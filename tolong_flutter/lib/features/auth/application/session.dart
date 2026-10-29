import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_vault.dart';
import '../../settings/local_data.dart';
import '../data/auth_repository.dart';

const guestOwner = 'guest';

class SessionState {
  const SessionState({
    this.ready = false,
    this.user,
    this.role,
    this.guest = false,
    this.onboardingComplete = false,
    this.recoveringPassword = false,
  });

  final bool ready;
  final AuthUserInfo? user;

  /// The signed-in user's server role, or null while unverified (see [canReview]).
  /// Guests and signed-out sessions always have this null.
  final AppUserRole? role;

  final bool guest;
  final bool onboardingComplete;
  final bool recoveringPassword;

  bool get signedIn => user != null;

  bool get isAdmin => signedIn && role == AppUserRole.admin;

  bool get canReview => signedIn && (role == AppUserRole.government || role == AppUserRole.admin);

  /// Key under which local data is stored: the account id, or the shared guest slot.
  String? get owner => user?.id ?? (guest ? guestOwner : null);

  SessionState copyWith({
    bool? ready,
    AuthUserInfo? Function()? user,
    AppUserRole? Function()? role,
    bool? guest,
    bool? onboardingComplete,
    bool? recoveringPassword,
  }) =>
      SessionState(
        ready: ready ?? this.ready,
        user: user != null ? user() : this.user,
        role: role != null ? role() : this.role,
        guest: guest ?? this.guest,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        recoveringPassword: recoveringPassword ?? this.recoveringPassword,
      );
}

class SessionController extends Notifier<SessionState> {
  StreamSubscription<AuthEvent>? _sub;

  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  SessionState build() {
    _sub = ref.watch(authRepositoryProvider).changes.listen(_onAuthEvent);
    ref.onDispose(() => _sub?.cancel());
    unawaited(_init());
    return const SessionState();
  }

  Future<void> _init() async {
    // Everything read here is already in memory, so the splash shows only for a frame.
    // (It used to wait a fixed 1.4 s, which made every launch feel slow.)
    await Future<void>.delayed(Duration.zero);
    final prefs = ref.read(sharedPreferencesProvider);
    final user = _auth.currentUser;
    state = state.copyWith(
      ready: true,
      user: () => user,
      guest: user == null && (prefs.getBool('guest_mode') ?? false),
      onboardingComplete: user != null && _onboardingDone(user.id),
    );
    // Role comes over the network; the splash must not wait for it. Fail-closed gating
    // (route guards read [SessionState.canReview]) keeps unverified sessions untrusted.
    unawaited(refreshRole());
  }

  /// Re-reads the role. Degrades to the least-privileged case when the lookup fails, so
  /// a signed-in user never gains government powers from a network error.
  Future<void> refreshRole() async {
    if (!state.signedIn) {
      state = state.copyWith(role: () => null);
      return;
    }
    final stored = await _auth.fetchRole();
    state = state.copyWith(role: () => stored ?? AppUserRole.user);
  }

  void _onAuthEvent(AuthEvent event) {
    final user = event.user;
    // Stale roles from a previous identity must not survive the account switch, even for
    // a moment: role is forced to null and only re-fetched after the event settles.
    state = state.copyWith(
      user: () => user,
      role: () => null,
      guest: user == null ? state.guest : false,
      onboardingComplete: user != null && _onboardingDone(user.id),
      recoveringPassword: event.type == AuthEventType.passwordRecovery ? true : null,
    );
    if (user != null && event.type != AuthEventType.passwordRecovery) {
      unawaited(refreshRole());
    }
  }

  bool _onboardingDone(String userId) =>
      ref.read(sharedPreferencesProvider).getBool('onboarding_complete:$userId') ?? false;

  Future<void> enterGuestMode() async {
    await ref.read(sharedPreferencesProvider).setBool('guest_mode', true);
    state = state.copyWith(guest: true);
  }

  Future<void> completeOnboarding() async {
    final id = state.user?.id;
    if (id == null) return;
    await ref.read(sharedPreferencesProvider).setBool('onboarding_complete:$id', true);
    state = state.copyWith(onboardingComplete: true);
  }

  void finishPasswordRecovery() => state = state.copyWith(recoveringPassword: false);

  /// Deletes the server account first; local data is removed only after that succeeds.
  Future<void> deleteAccount() async {
    final id = state.user?.id;
    if (id == null) return;
    await _auth.deleteAccount();
    await wipeLocalData(ref, id, keepProfile: false);
    await ref.read(sharedPreferencesProvider).remove('onboarding_complete:$id');
    state = state.copyWith(user: () => null, role: () => null, guest: false, onboardingComplete: false);
  }

  /// Ends the account session or guest mode. Local data is kept so it stays available offline.
  Future<void> signOut() async {
    await ref.read(sharedPreferencesProvider).setBool('guest_mode', false);
    if (state.signedIn) await _auth.signOut();
    state = state.copyWith(
      user: () => null,
      role: () => null,
      guest: false,
      onboardingComplete: false,
      recoveringPassword: false,
    );
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
