import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/demo.dart';
import '../features/auth/application/session.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/password_screens.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/demo/presentation/demo_tools_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/household/presentation/profile_screen.dart';
import '../features/more/more_screen.dart';
import '../features/offline/offline_readiness_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/prepare/presentation/prepare_screen.dart';
import '../features/readiness/presentation/readiness_screen.dart';
import '../features/safe_places/domain/shelter_submission.dart';
import '../features/safe_places/presentation/admin_accounts_screen.dart';
import '../features/safe_places/presentation/my_submissions_screen.dart';
import '../features/safe_places/presentation/offline_map_screen.dart';
import '../features/safe_places/presentation/review_shelters_screen.dart';
import '../features/safe_places/presentation/safe_places_screen.dart';
import '../features/safe_places/presentation/submit_shelter_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/supplies/presentation/supplies_screen.dart';
import '../features/tol/presentation/tol_chat_screen.dart';
import 'app_shell.dart';

const _publicRoutes = {'/welcome', '/login', '/register', '/forgot-password'};

/// Pure routing decision so it can be unit tested without widgets. [demoToolsEnabled] keeps
/// the `/demo` admin route unreachable in normal builds even through deep links.
///
/// Role-gated routes fail closed: when the session's role is not yet verified
/// (`SessionState.canReview`), a deep link into review or admin screens lands on `/home`.
@visibleForTesting
String? redirectFor(SessionState s, String location, {bool demoToolsEnabled = false}) {
  if (location.startsWith('/demo') && !demoToolsEnabled) return '/home';
  if (!s.ready) return location == '/splash' ? null : '/splash';
  if (s.recoveringPassword) return location == '/reset-password' ? null : '/reset-password';
  if (!s.signedIn && !s.guest) return _publicRoutes.contains(location) ? null : '/welcome';
  if (s.signedIn && !s.onboardingComplete) return location == '/onboarding' ? null : '/onboarding';
  if (_publicRoutes.contains(location) ||
      location == '/splash' ||
      location == '/onboarding' ||
      location == '/reset-password') {
    return '/home';
  }
  if ((location == '/submit-shelter' || location == '/my-submissions') && !s.signedIn) {
    return '/welcome';
  }
  if (location == '/review-shelters' && !s.canReview) return '/home';
  if (location == '/admin' && !s.isAdmin) return '/home';
  return null;
}

StatefulShellBranch _tab(String path, int index, Widget child) => StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (_, __) => TabPage(index: index, child: child))],
    );

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);
  // Registered only when the build compiled with demo tools on (see core/config/demo.dart):
  // a release bundle without the define has no `/demo` route and no entry points at all.
  final demoEnabled = ref.watch(demoToolsEnabledProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        redirectFor(ref.read(sessionProvider), state.matchedLocation, demoToolsEnabled: demoEnabled),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/supplies', builder: (_, __) => const SuppliesScreen()),
      GoRoute(path: '/readiness', builder: (_, __) => const ReadinessScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/offline-map', builder: (_, __) => const OfflineMapScreen()),
      GoRoute(path: '/offline-readiness', builder: (_, __) => const OfflineReadinessScreen()),
      GoRoute(path: '/tol', builder: (_, __) => const TolChatScreen()),
      GoRoute(
        path: '/submit-shelter',
        builder: (_, state) => SubmitShelterScreen(
          initial: state.extra is ShelterSubmission ? state.extra as ShelterSubmission : null,
        ),
      ),
      GoRoute(path: '/my-submissions', builder: (_, __) => const MySubmissionsScreen()),
      GoRoute(path: '/review-shelters', builder: (_, __) => const ReviewSheltersScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminAccountsScreen()),
      if (demoEnabled) GoRoute(path: '/demo', builder: (_, __) => const DemoToolsScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          _tab('/home', 0, const HomeScreen()),
          _tab('/prepare', 1, const PrepareScreen()),
          _tab('/safe-places', 2, const SafePlacesScreen()),
          _tab('/more', 3, const MoreScreen()),
        ],
      ),
    ],
  );
});
