import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/config/env.dart';
import 'core/storage/secure_vault.dart';
import 'core/theme.dart';
import 'features/safe_places/data/hazard_layer_service.dart';
import 'features/safe_places/data/hazard_protocol.dart';
import 'features/settings/settings.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['DM Sans'], await rootBundle.loadString('assets/fonts/DMSans-OFL.txt'));
    yield LicenseEntryWithLineBreaks(['Fraunces'], await rootBundle.loadString('assets/fonts/Fraunces-OFL.txt'));
  });
  final prefs = await SharedPreferences.getInstance();
  if (Env.supabaseConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(localStorage: SecureSessionStorage()),
    );
  }
  // Web only, and only once MapLibre GL JS is present: the map loads that library itself, so
  // `maplibregl` does not exist while index.html is parsed. Android and iOS resolve `pmtiles://`
  // inside MapLibre Native and need none of this.
  //
  // Neither step may stop the app from starting. `registerPmTilesProtocol` catches its own
  // failures; `ensureWebLibraryLoaded` is wrapped because a map that will not load is still a map
  // the rest of the app can run without. Either way the hazard overlay reports itself
  // unavailable, which is a far better outcome than a blank screen.
  if (kIsWeb) {
    try {
      await MapLibreMap.ensureWebLibraryLoaded();
      setPmTilesRegistered(registerPmTilesProtocol(hazardArchiveUrl));
    } catch (error) {
      debugPrint('Web map library unavailable, continuing without it: $error');
      setPmTilesRegistered(false);
    }
  } else {
    setPmTilesRegistered(true);
  }
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const TolongApp(),
  ));
}

class TolongApp extends ConsumerWidget {
  const TolongApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: Locale(settings.language.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            disableAnimations: mq.disableAnimations || settings.reducedMotion,
            textScaler: TextScaler.linear(mq.textScaler.scale(1) * settings.textSize.factor),
          ),
          child: child!,
        );
      },
    );
  }
}
