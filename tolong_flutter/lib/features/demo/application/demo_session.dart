import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo.dart';
import '../../safe_places/domain/evacuation_center.dart';
import '../domain/demo_models.dart';

/// Holds every simulated input for the current run. In-memory only: nothing is persisted,
/// so a hot restart or a fresh launch starts clean, and a normal (non-demo) build never
/// runs this controller at all — `main()` only installs the demo wrappers when the
/// `DEMO_TOOLS` define is on.
class DemoSessionController extends Notifier<DemoState> {
  @override
  DemoState build() => const DemoState();

  void setLocationOverride(GeoPoint? point) =>
      state = state.copyWith(locationOverride: point, clearLocationOverride: point == null);

  void setAdvisory(DemoAdvisory? advisory) => state = state.copyWith(
        advisory: advisory,
        clearAdvisory: advisory == null,
        advisoryRevision: state.advisoryRevision + 1,
      );

  void setWeightsMode(DemoWeightsMode mode) => state = state.copyWith(weightsMode: mode);

  void setFakeRoute(bool enabled) => state = state.copyWith(fakeRoute: enabled);

  /// Back to launch defaults: no override, no advisory, trained weights, real routes.
  void reset() => state = const DemoState();
}

final demoSessionProvider = NotifierProvider<DemoSessionController, DemoState>(
  DemoSessionController.new,
);

/// The advisory Home shows. Always null in normal builds — the type reveals itself to the
/// compiler, so not even an accidental non-null advisory can reach Home without the flag.
final demoAdvisoryProvider = Provider<DemoAdvisory?>((ref) {
  if (!ref.watch(demoToolsEnabledProvider)) return null;
  return ref.watch(demoSessionProvider.select((s) => s.advisory));
});

class _AdvisoryDismissed extends Notifier<int> {
  @override
  int build() => -1;

  void dismiss() => state = ref.read(demoSessionProvider).advisoryRevision;
}

/// Stores which advisory revision the user last dismissed on Home, so a changed scenario
/// reappears (a bumped revision) while leaving the same scenario dismissed.
final advisoryDismissedRevisionProvider = NotifierProvider<_AdvisoryDismissed, int>(
  _AdvisoryDismissed.new,
);

/// True whenever the demo tools should announce themselves app-wide with the banner.
final demoBannerActiveProvider = Provider<bool>((ref) {
  if (!ref.watch(demoToolsEnabledProvider)) return false;
  return ref.watch(demoSessionProvider.select((s) => s.hasOverrides));
});
