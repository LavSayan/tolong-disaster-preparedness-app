import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'core/config/env.dart';
import 'core/storage/secure_vault.dart';
import 'core/theme.dart';
import 'features/safe_places/data/hazard_archive.dart';
import 'features/safe_places/data/hazard_layer_service.dart';
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
  // Preparing the hazard archive: on web it registers the `pmtiles://` protocol with MapLibre
  // GL JS (which the map loads itself, so `maplibregl` does not exist while index.html is
  // parsed); on Android and iOS it extracts the bundled archive to a seekable file. See
  // `hazard_archive.dart`.
  //
  // This must not stop the app from starting: `prepareHazardArchive` reports `null` on any
  // failure instead of throwing, and the hazard overlay then reports itself unavailable —
  // a far better outcome than a blank screen. A missing flood layer is an inconvenience; an
  // app that will not launch is a disaster in itself.
  try {
    final archiveUrl = await prepareHazardArchive();
    setHazardArchiveUrl(archiveUrl);
    setPmTilesRegistered(archiveUrl != null);
  } catch (error) {
    debugPrint('Hazard archive unavailable, continuing without it: $error');
    setHazardArchiveUrl(null);
    setPmTilesRegistered(false);
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
