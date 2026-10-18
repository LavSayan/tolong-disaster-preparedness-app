import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/storage/secure_vault.dart';
import '../domain/tol_models.dart';

enum TolErrorCode { notConfigured, network, quota, server }

class TolFailure implements Exception {
  const TolFailure(this.code);
  final TolErrorCode code;
}

abstract interface class OnlineTolService {
  Future<String> ask({
    required List<Map<String, String>> conversation,
    required String language,
    required TolFacts facts,
    Map<String, Object?>? context,
  });
}

/// Calls the `tol-chat` Edge Function, which holds the AI provider key.
class EdgeFunctionTolService implements OnlineTolService {
  @override
  Future<String> ask({
    required List<Map<String, String>> conversation,
    required String language,
    required TolFacts facts,
    Map<String, Object?>? context,
  }) async {
    try {
      final res = await Supabase.instance.client.functions.invoke('tol-chat', body: {
        'messages': conversation,
        'language': language,
        'facts': facts.toJson(),
        if (context != null) 'context': context,
      });
      final reply = (res.data is Map) ? (res.data as Map)['reply'] as String? : null;
      if (reply == null || reply.trim().isEmpty) throw const TolFailure(TolErrorCode.server);
      return reply.trim();
    } on TolFailure {
      rethrow;
    } on FunctionException catch (e) {
      throw TolFailure(switch (e.status) {
        429 => TolErrorCode.quota,
        503 || 404 => TolErrorCode.notConfigured,
        _ => TolErrorCode.server,
      });
    } catch (e) {
      debugPrint('Tol request failed: ${e.runtimeType}');
      throw const TolFailure(TolErrorCode.network);
    }
  }
}

/// Null when the build has no Supabase configuration; Tol then works offline only.
final onlineTolServiceProvider =
    Provider<OnlineTolService?>((ref) => Env.supabaseConfigured ? EdgeFunctionTolService() : null);

/// Chat history, encrypted on device per owner (messages may contain personal details).
class TolHistoryRepository {
  TolHistoryRepository(this._vault);

  final SecureVault _vault;
  static const keep = 60;

  Future<List<TolMessage>> load(String owner) async {
    final raw = await _vault.read('tol:$owner');
    if (raw == null) return [];
    return [for (final m in jsonDecode(raw) as List) TolMessage.fromJson(m as Map<String, Object?>)];
  }

  Future<void> save(String owner, List<TolMessage> messages) {
    final recent = messages.length > keep ? messages.sublist(messages.length - keep) : messages;
    return _vault.write('tol:$owner', jsonEncode([for (final m in recent) m.toJson()]));
  }

  Future<void> clear(String owner) => _vault.delete('tol:$owner');
}

final tolHistoryRepositoryProvider = Provider((ref) => TolHistoryRepository(ref.watch(secureVaultProvider)));
