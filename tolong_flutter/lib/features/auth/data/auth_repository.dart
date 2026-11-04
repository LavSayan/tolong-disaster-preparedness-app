import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../household/domain/models.dart';

class AuthUserInfo {
  const AuthUserInfo({required this.id, this.email, this.fullName, this.age, this.barangay});

  final String id;
  final String? email;
  final String? fullName;
  final int? age;
  final String? barangay;
}

/// Server-side role from `profiles.role`, seeded by the project owner and granted by
/// admins (see supabase/migrations/20261029000000_roles.sql). Government *and* admin
/// review submissions; admins additionally manage accounts. Guests carry no role.
enum AppUserRole { user, government, admin }

AppUserRole? appUserRoleFrom(String? code) => switch (code) {
      'government' => AppUserRole.government,
      'admin' => AppUserRole.admin,
      'user' => AppUserRole.user,
      _ => null,
    };

enum AuthEventType { changed, signedOut, passwordRecovery }

class AuthEvent {
  const AuthEvent(this.type, this.user);

  final AuthEventType type;
  final AuthUserInfo? user;
}

enum SignUpResult { signedIn, needsEmailVerification }

enum AuthErrorCode {
  notConfigured,
  network,
  invalidCredentials,
  emailNotConfirmed,
  alreadyRegistered,
  rateLimited,
  weakPassword,
  unknown,
}

/// Carries a code, not text, so the UI can show it in the user's language.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthFailure($code)';
}

abstract interface class AuthRepository {
  bool get isConfigured;
  AuthUserInfo? get currentUser;
  Stream<AuthEvent> get changes;

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String barangay,
    required String languageCode,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String newPassword);
  Future<void> signOut();

  /// Deletes the signed-in user's account on the server (profile rows cascade).
  Future<void> deleteAccount();

  /// Reads the signed-in user's role from the `profiles` table. Returns null (never
  /// throws) so a failed lookup degrades to the least-privileged case; the session
  /// fallback is [AppUserRole.user].
  Future<AppUserRole?> fetchRole();

  /// Best-effort push of profile fields to the `profiles` table. Local data stays authoritative offline.
  Future<void> syncProfile(UserProfile profile);
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;
  GoTrueClient get _auth => _client.auth;

  @override
  bool get isConfigured => true;

  @override
  AuthUserInfo? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthEvent> get changes => _auth.onAuthStateChange.map((s) => AuthEvent(
        switch (s.event) {
          AuthChangeEvent.passwordRecovery => AuthEventType.passwordRecovery,
          AuthChangeEvent.signedOut => AuthEventType.signedOut,
          _ => AuthEventType.changed,
        },
        _map(s.session?.user),
      ));

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String barangay,
    required String languageCode,
  }) =>
      _guard(() async {
        final res = await _auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: Env.authRedirectUrl,
          data: {
            'full_name': fullName,
            'age': age,
            'barangay': barangay,
            'preferred_language': languageCode,
            'privacy_accepted_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
        return res.session != null ? SignUpResult.signedIn : SignUpResult.needsEmailVerification;
      });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.resetPasswordForEmail(email, redirectTo: Env.authRedirectUrl));

  @override
  Future<void> updatePassword(String newPassword) =>
      _guard(() => _auth.updateUser(UserAttributes(password: newPassword)));

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() => _guard(() async {
        await _client.rpc('delete_own_account');
        await _auth.signOut(scope: SignOutScope.local);
      });

  @override
  Future<void> syncProfile(UserProfile profile) async {
    final id = _auth.currentUser?.id;
    if (id == null) return;
    try {
      await _client.from('profiles').update({
        'full_name': profile.fullName,
        'age': profile.age,
        'barangay': profile.barangay,
        'preferred_language': profile.language.code,
      }).eq('id', id);
    } catch (e) {
      debugPrint('Profile sync deferred: ${e.runtimeType}');
    }
  }

  @override
  Future<AppUserRole?> fetchRole() async {
    final id = _auth.currentUser?.id;
    if (id == null) return null;
    try {
      final row = await _client.from('profiles').select('role').eq('id', id).single();
      return appUserRoleFrom(row['role'] as String?);
    } catch (e) {
      debugPrint('Role fetch failed: ${e.runtimeType}');
      return null;
    }
  }

  AuthUserInfo? _map(User? u) {
    if (u == null) return null;
    final meta = u.userMetadata ?? const {};
    return AuthUserInfo(
      id: u.id,
      email: u.email,
      fullName: meta['full_name'] as String?,
      age: (meta['age'] as num?)?.toInt(),
      barangay: meta['barangay'] as String?,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthRetryableFetchException {
      throw const AuthFailure(AuthErrorCode.network);
    } on AuthException catch (e) {
      throw AuthFailure(_classify(e));
    } catch (e) {
      debugPrint('Auth error: ${e.runtimeType}');
      throw const AuthFailure(AuthErrorCode.unknown);
    }
  }

  AuthErrorCode _classify(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return AuthErrorCode.invalidCredentials;
    if (m.contains('email not confirmed')) return AuthErrorCode.emailNotConfirmed;
    if (m.contains('already registered')) return AuthErrorCode.alreadyRegistered;
    if (m.contains('rate limit') || e.statusCode == '429') return AuthErrorCode.rateLimited;
    if (m.contains('weak') || m.contains('password should')) return AuthErrorCode.weakPassword;
    return AuthErrorCode.unknown;
  }
}

/// Used when the build has no Supabase configuration, so account features fail honestly.
class UnconfiguredAuthRepository implements AuthRepository {
  static const _failure = AuthFailure(AuthErrorCode.notConfigured);

  @override
  bool get isConfigured => false;

  @override
  AuthUserInfo? get currentUser => null;

  @override
  Stream<AuthEvent> get changes => const Stream.empty();

  @override
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required int age,
    required String barangay,
    required String languageCode,
  }) async =>
      throw _failure;

  @override
  Future<void> signIn({required String email, required String password}) async => throw _failure;

  @override
  Future<void> sendPasswordReset(String email) async => throw _failure;

  @override
  Future<void> updatePassword(String newPassword) async => throw _failure;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async => throw _failure;

  @override
  Future<void> syncProfile(UserProfile profile) async {}

  @override
  Future<AppUserRole?> fetchRole() async => null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Env.supabaseConfigured ? SupabaseAuthRepository() : UnconfiguredAuthRepository(),
);
