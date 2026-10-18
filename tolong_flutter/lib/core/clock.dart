import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridable "now" so expiry and greeting logic can be tested.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
