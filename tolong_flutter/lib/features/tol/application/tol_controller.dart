import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../l10n/l10n.dart';
import '../../auth/application/session.dart';
import '../../household/data/household_repository.dart';
import '../../readiness/application/readiness_providers.dart';
import '../../safe_places/data/evacuation_center_repository.dart';
import '../../settings/settings.dart';
import '../data/tol_service.dart';
import '../domain/offline_guide.dart';
import '../domain/tol_models.dart';

class TolState {
  const TolState({this.messages = const [], this.sending = false, this.loaded = false});

  final List<TolMessage> messages;
  final bool sending;
  final bool loaded;

  TolState copyWith({List<TolMessage>? messages, bool? sending, bool? loaded}) => TolState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        loaded: loaded ?? this.loaded,
      );
}

/// Online AI needs an account (the Edge Function requires a signed-in user) and a configured backend.
final tolOnlineAvailableProvider = Provider<bool>((ref) =>
    ref.watch(onlineTolServiceProvider) != null && ref.watch(sessionProvider.select((s) => s.signedIn)));

class TolController extends Notifier<TolState> {
  String? get _owner => ref.read(sessionProvider).owner;

  @override
  TolState build() {
    final owner = ref.watch(sessionProvider.select((s) => s.owner));
    if (owner != null) unawaited(_load(owner));
    return const TolState();
  }

  Future<void> _load(String owner) async {
    final history = await ref.read(tolHistoryRepositoryProvider).load(owner);
    if (ref.mounted) state = state.copyWith(messages: history, loaded: true);
  }

  String _id() => '${ref.read(clockProvider)().microsecondsSinceEpoch}';

  void _append(TolMessage m) {
    state = state.copyWith(messages: [...state.messages, m]);
    final owner = _owner;
    if (owner != null) unawaited(ref.read(tolHistoryRepositoryProvider).save(owner, state.messages));
  }

  /// Sends [text]. Tries online AI when available, otherwise (or on failure) answers offline.
  /// [l] supplies the current language for offline answers.
  Future<void> send(String text, AppLocalizations l) async {
    final question = text.trim();
    if (question.isEmpty || state.sending) return;
    _append(TolMessage(id: _id(), role: TolRole.user, text: question, createdAt: ref.read(clockProvider)()));
    await _answer(l);
  }

  /// Asks the last question online again after an offline fallback.
  Future<void> retryOnline(AppLocalizations l) => _answer(l);

  Future<void> _answer(AppLocalizations l) async {
    final lastQuestion = state.messages.lastWhere((m) => m.role == TolRole.user).text;
    state = state.copyWith(sending: true);
    var failedOnline = false;
    try {
      final service = ref.read(onlineTolServiceProvider);
      if (ref.read(tolOnlineAvailableProvider) && service != null) {
        try {
          final reply = await service.ask(
            conversation: conversationForApi([for (final m in state.messages) if (!m.onlineFailed) m]),
            language: l.localeName,
            facts: _facts(),
            context: ref.read(settingsProvider).tolContextConsent ? _context() : null,
          );
          _append(TolMessage(
            id: _id(),
            role: TolRole.tol,
            text: reply,
            mode: TolMode.online,
            createdAt: ref.read(clockProvider)(),
          ));
          return;
        } on TolFailure {
          failedOnline = true;
        }
      }
      _append(TolMessage(
        id: _id(),
        role: TolRole.tol,
        text: offlineAnswer(l, lastQuestion, _snapshot()),
        mode: TolMode.offline,
        onlineFailed: failedOnline,
        createdAt: ref.read(clockProvider)(),
      ));
    } finally {
      if (ref.mounted) state = state.copyWith(sending: false);
    }
  }

  Future<void> clear() async {
    state = state.copyWith(messages: const []);
    final owner = _owner;
    if (owner != null) await ref.read(tolHistoryRepositoryProvider).clear(owner);
  }

  TolFacts _facts() {
    final centers = ref.read(evacuationCentersProvider).value ?? const [];
    return TolFacts(
      alertsConnected: false,
      centersVerified: centers.isNotEmpty && centers.every((c) => c.verified),
    );
  }

  Map<String, Object?> _context() {
    final data = ref.read(householdProvider).value;
    return householdSummary(
      household: data?.household,
      profile: data?.profile,
      readiness: ref.read(readinessProvider),
    );
  }

  OfflineSnapshot _snapshot() => OfflineSnapshot(
        checklist: ref.read(checklistItemsProvider),
        readiness: ref.read(readinessProvider),
        recommendations: ref.read(recommendationsProvider),
        contactCount: ref.read(householdProvider).value?.contacts.length ?? 0,
      );
}

final tolProvider = NotifierProvider<TolController, TolState>(TolController.new);
