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
- Phase 6 hazard-aware A\* routing was deferred by the team; the shelter-ranking part has a spec
  (`docs/SHELTER_RANKING_ML.md`) but is not implemented. The modelled-hazard **overlay** ships
  (see §9).

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

## 9. Update 2026-10-20 — hazard overlay and PSGC cross-check

### What changed in the suite

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **174 passed, 0 failed** (was 145) |

New since the 2026-10-18 report:

- `hazard_layer_test.dart` (28 tests): bundled PMTiles archives exist and are real, hazard
  grouping and layer specs are unique per severity band, every band layer filters on its own
  severity code (`Var` for flood, `HAZ` for the rest — regression tests for a bug where bands
  rendered without filters), legend wording never claims safety, the picker degrades honestly
  when the PMTiles protocol fails to register.
- `qc_area_test.dart` gains a fixture test: barangay names and codes must match
  `test/fixtures/psgc_qc_official.json` exactly — the PSA PSGC masterlist
  (Third Quarter 2026 release, 2026-10-12) with provenance, since psa.gov.ph refuses automated
  downloads and the datafile was taken from a validated mirror.
- `tools/psgc_crosscheck/crosscheck.py`: same check outside Dart (`--check`), plus
  `--extract` to rebuild the fixture from a fresh mirror datafile.

Data corrections while cross-checking: 5 barangays carried old 9-digit correspondence codes
(now `13813000xx`), and 9 names were aligned to PSA's official spellings.

### What was **not** re-verified on hardware

- The debug APK was rebuilt (`flutter build apk --debug`) but the emulator pass was abandoned —
  the emulator would not reach a stable boot on the 8 GB laptop this session. The SETUP Phase 3
  manual checklist (rows 30–47, plus the hazard overlay steps) was handed to the team to run on
  a real phone; results should be appended here.
- Everything needing a backend (routes, Tol online, sync) is still untested — no Supabase project yet.

## 10. Update 2026-10-20 — hazard overlay transport fix

A manual Chrome check (`flutter run -d chrome`) found the hazard picker and legend working but no
colours on the map, with no 404. Diagnosis: protocol registration, the map source and the band
layers were all fine — pmtiles' HTTP `FetchSource` requires the server to honour **byte ranges**,
and Flutter's dev server (like any plain static server) answers a `Range` request with a 200 and
the whole 51 MB, which the library rejects. A documented claim that "Flutter's dev server handles
it" was wrong.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **176 passed, 0 failed** (was 174) |

Changes:

- Web loads the archive as a **whole file** into a `File`-backed pmtiles `FileSource`
  (`web/vendor/hazard_archive.js` glue + a rewritten `hazard_protocol_web.dart`) — no byte-serving
  dependency, so the overlay works in `flutter run -d chrome` and on any static host. Cost: one
  51 MB fetch per page load, on first overlay use.
- Android/iOS extract the bundled archive once into the app-support directory (atomic `.part` +
  rename, `hazard_archive.dart`); the map reads `pmtiles://<extracted path>`, because MapLibre
  Native cannot open a bundled asset through `pmtiles://` at all (deflated APK entry, no
  filesystem path).
- The registered key is now derived from one constant (`hazardArchiveKey` in `map_style.dart`),
  fixing a latent mismatch where `main()` registered the *prefixed* URL; `hazard_layer_test.dart`
  asserts the key equals the source URL minus the scheme and dropped a `build/web` check that
  passed vacuously.

### What is **not** verified yet (manual checks pending)

- ~~Chrome colours after the fix~~ **Verified later the same day (§11)**: colours render once
  the numeric filter is in; see §11.
- Android extraction on a real phone — including whether MapLibre Native accepts the
  `pmtiles:///data/…` path form.
- 51 MB cost acceptance: web fetch-per-page-load, Android first-run copy.

## 11. Update 2026-10-20 — the real cause: filter compared a string to a number

A second Chrome check still showed legend with no colours and — crucially — **no error**. That
ruled the transport out and pointed at a silent filter problem. Decoding the bundled archive
directly (tile z14/13697/7520, then every tile) settled it: `Var`/`HAZ` are stored as **numbers**
(`INT 1..3/1..4`), while the style filter compared them against the **string** codes `'1'…'4'`.
MapLibre's `==` compares types strictly, so `1 == '1'` is false for every feature: zero matches,
no fills, no exception. The legend rendered as before, because it is driven by `band.level`, not
by what the map drew. The earlier "transport fix" was still a real defect (the dev server
legitimately cannot byte-serve) but was not what the user saw.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **195 passed, 0 failed** (was 176) |
| `python tools/hazard_archive_check/hazard_fields.py --check` | OK: 9 layers match the committed fixture |

Changes:

- `HazardSeverityBand.code` is now an `int`, and the filter emits
  `['==', ['get','Var'], 1]` — numeric, matching the archive. Layer ids are unchanged.
- **The data backs the ranges.** `tools/hazard_archive_check/hazard_fields.py` decodes **all 169
  tiles** (stdlib-only, reuses the proven PMTiles directory/MVT decoding) and writes
  `test/fixtures/hazard_archive_fields.json` — per layer: attribute, storage type, observed
  values (`flood*` Var {1,2,3}; `landslide` HAZ {1,2,3,4}; surge {1,2,3}; `debris_flow` {3,4};
  archive sha256/size/tiles as provenance). `--check` re-decodes and diffs. New
  `hazard_archive_fields_test.dart` (13 tests) asserts every group's attribute is present and
  numeric in all of its source layers and that **every observed value has a declared band**.
  The reverse (a declared band with no data) is allowed on purpose: the legend shows the full
  scale for groups whose QC extract uses only part of it.
- **Silent failures are visible now.** `hazard_layer_service.dart` gained a pure
  `classifyDraw` + `HazardDrawState`; `map_view.dart` hooks `onMapIdle`: with an active group it
  queries the source unfiltered and again under a new whole-group filter
  (`hazardGroupFilterExpression`; `['in', ['get', attr], [codes]]`), classifying `drawn`,
  `viewHasNoData` (stays quiet: normal for empty tiles) or `filterMatchedNothing`. That last
  state — data loaded, filter matched none — reaches the legend as a short note
  (`hazardNothingDrawn`, both languages, generated); it is worded as an app-problem report,
  never as evidence the hazard is absent. The comparison cannot happen on a colourless run
  again without the legend saying so.
- `HazardLayerSpec` group-filter and draw-state helpers are unit-tested in
  `hazard_layer_test.dart` (+6 tests, now 36), including a regression test asserting the filter
  code is an `int`.

### What is **not** verified yet (manual checks pending)

- ~~Chrome colours after both fixes~~ **Verified 2026-10-20**: a full `flutter run -d chrome`
  restart loaded the new `web/vendor/hazard_archive.js` script tag (it does not load on a
  hot-reload of an already-open page) and the hazard colours now render, with the
  `hazardNothingDrawn` note correctly staying hidden.
- Android extraction on a real phone — including whether MapLibre Native accepts the
  `pmtiles:///data/…` path form.
- 51 MB cost acceptance: web fetch-per-page-load, Android first-run copy.
