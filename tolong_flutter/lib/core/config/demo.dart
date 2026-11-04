import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compiled-in switch for the demo/admin tools. Normal builds have no demo code path at all:
/// run with `--dart-define=DEMO_TOOLS=true` to build a demo variant that can fake its inputs
/// (location, advisories, routes, weights). Never distribute a build started with this flag.
const bool demoToolsEnabled = bool.fromEnvironment('DEMO_TOOLS');

/// Provider indirection so the router, entries and tests can read the switch without every
/// widget depending on a compile-time const directly.
final demoToolsEnabledProvider = Provider<bool>((ref) => demoToolsEnabled);
