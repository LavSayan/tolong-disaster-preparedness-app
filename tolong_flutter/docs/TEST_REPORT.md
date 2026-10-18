# TolongApp — Phase 7 Test Report

Date: 2026-10-18 · App version 0.5.0+5 · Flutter 3.47.7 / Dart 3.13.5 · Windows 10, 8 GB RAM

This report says what was tested, how, and what was **not** tested. Supabase setup and Phase 6
(hazard-aware routing) were skipped at the team's request, so anything that needs a backend is
listed under "Not executed".

## 1. Summary

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **145 passed, 0 failed** |
| Accessibility guidelines (12 screens) | Pass after fixes (see §3) |
| Small screens and large text (37 route checks) | Pass after fixes (see §4) |
| Release APK (`flutter build apk --release`) | Built, **96.9 MB** universal APK (all CPU types). With `--split-per-abi`: **34.6 MB** (arm64, most phones), 29.7 MB (older 32-bit) |
| Real Android device | **Not tested** |
| Supabase auth, backup sync, Edge Functions (routes, Tol online) | **Not tested**: no project yet |

## 2. Automated test suite

| File | What it covers |
|---|---|
| `unit_test.dart` | Auth redirects, validation, water/food coverage maths, readiness score, checklist merge, greetings
| `widget_test.dart` | Welcome without backend, honest login error, guest mode, every tab, Filipino switch |
| `onboarding_test.dart` | Onboarding to dashboard, Filipino chosen during onboarding
| `phase2_flows_test.dart` | Checklist, custom items, supplies → Home coverage, settings and reduced motion, account deletion
| `safe_places_test.dart` | Map with demo labels, marker taps, nearest center, outside-QC, location denied/blocked/off |
| `qc_area_test.dart` | QC boundary, 142 barangays, barangay search, offline map download/delete |
| `routing_test.dart` | Route drawing, wheelchair profile, route errors, navigation off-route/arrival |
| `phase4_test.dart` | Guidebook (no uncited content), Offline Readiness Center, queued backup |
| `sync_store_test.dart`, `sync_engine_test.dart` | Queue coalescing, tombstones, "newer change wins", retry when server unreachable |
| `tol_test.dart` | Offline intents (EN/FIL), no personal data in AI context, consent, online→offline fallback |
| `responsive_test.dart` | Every route at 320×568 and 320×2400 dp, in Filipino with larger text, with no overflow |
| `accessibility_test.dart` | Flutter's tap-target (48 dp), labelled-control and WCAG text-contrast guidelines |
| `error_states_test.dart` | Unreadable center data, unreadable guidebook, failed offline map download |

Backends are replaced with fakes (map, GPS, routing, offline tiles, sync server, Tol, auth), so these
tests prove the app's own logic and UI, not the real services.

## 3. Accessibility fixes made in Phase 7

- **Tap targets** raised to 48 dp: header icons, profile avatar (visible circle unchanged), Tol
  button, welcome EN/FIL switch, barangay search bar, flood-alert sound toggle.
- **Text contrast** raised to at least 4.5:1: muted text, eyebrow labels, dates, footers, nav
  labels, warning/success/error text, info and success messages, guest banner. The primary sage
  was deepened slightly (#63896D → #52775D) so white text on buttons passes. Decorative tints and
  chevrons are unchanged.
- The flood-alert `AudioPlayer` is now created on first tap instead of on screen load.

## 4. Responsiveness fixes (earlier in Phase 7)

Fixed overflows found at 320 dp width and large text: profile section headers, supplies
essentials grid (now wraps and grows), readiness area points, Tol mode chip, supply expiry field,
and all bottom sheets (now scroll). Fonts are bundled (DM Sans, Fraunces, OFL) so text renders the
same offline; the app no longer downloads fonts.

## 5. Not executed (needs hardware or a backend)

| Area | Why not | How to test |
|---|---|---|
| GPS, map gestures, performance on a phone | No device connected | `docs/SETUP.md` manual checklist, Phase 3 rows |
| Offline map in airplane mode | Needs device + MapLibre native | SETUP rows for offline maps |
| Sign up / login / password reset / delete account | No Supabase project | Create project, apply 3 migrations, `env.json` |
| Backup sync across two phones | No Supabase project | SETUP Phase 4 rows |
| Walking routes (`tol-route`) | Edge Function not deployed, no ORS key | SETUP "Walking routes" |
| Tol online (`tol-chat`) | Edge Function not deployed, no AI key | SETUP "Tol online", rows 57–63 |
| TalkBack screen-reader walkthrough | Needs device | Turn on TalkBack and go through each tab |

## 6. Known issues before any public release

- `applicationId` is still `com.example.tolong_flutter`; Google Play rejects `com.example`. Pick the
  real ID (for example `ph.gov.qc.tolong` or the team's domain) before the first upload.
  It can't be changed after publishing.
- Release builds are signed with the **debug key**. Create an upload keystore and a
  `key.properties` (kept out of git) before distributing.
- Evacuation centers are **demo data**, clearly labelled; hazard alerts have no data source;
  the guidebook has no content yet. All are shown honestly in the app.
- Phase 6 (hazard-aware A* routing) not started.

## 7. Build notes

- The first release build failed: Android lint ran out of Metaspace on the `audioplayers` plugin.
  Fixed by raising `-XX:MaxMetaspaceSize` from 512m to 1024m in `android/gradle.properties`
  (heap stays at 1.5 GB for the 8 GB laptop). Second build: 5.5 minutes.
- The APK is large because MapLibre ships native libraries for each CPU type. For sharing a test
  build, use `flutter build apk --release --split-per-abi` and install `app-arm64-v8a-release.apk`;
  for Play, upload `flutter build appbundle`.
- Material icons are tree-shaken (1.6 MB → 15 KB).

## 8. Start-up fix (after the report)

- Removed a fixed 1.4 s wait on the splash screen; the session is ready as soon as saved settings are read.
- The Android launch screen (shown until Flutter draws its first frame) is now the app's cream
  background instead of white, including the Android 12+ system splash.
- The app icon is still Flutter's default logo, so it isn't shown on the launch screen. A real
  TolongApp icon is needed.
- Debug builds (`flutter run`) still start slowly on a phone; that's normal for debug mode.
  Use the release APK to judge start-up time.
