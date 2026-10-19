# TolongApp — File Structure

A lookup table: **"I want to change X → open these files."**

For *why* the code is shaped this way, read [`ARCHITECTURE.md`](ARCHITECTURE.md). This
document is the map; that one is the reasoning.

Every `lib/…` path below is relative to `tolong_flutter/`.

---

## 1. Orientation

The Flutter app is `tolong_flutter/`. The Supabase backend is `tolong_flutter/supabase/`.
Both `flutter` and `flutter test` must be run from inside `tolong_flutter/`.

```
pubspec.yaml                  dependencies + assets + fonts
analysis_options.yaml         lint rules (flutter_lints)
build.yaml                    drift codegen config
l10n.yaml                     ARB → lib/l10n/generated/
env.example.json              template for env.json (git-ignored)

lib/
├── main.dart                 67   entry: boots Supabase, ProviderScope, TolongApp
├── app/
│   ├── router.dart           88   all routes + redirectFor() auth gate
│   └── app_shell.dart       253   header, bottom nav, tab frame, TolFab
├── core/
│   ├── theme.dart           193   ★ design tokens — start here for any visual change
│   ├── validation.dart       70   email / PH phone / landline / password rules
│   ├── clock.dart             4   injectable DateTime for deterministic tests
│   ├── config/env.dart       14   the two build-time config values
│   ├── database/            62   Drift tables (sync bookkeeping only)
│   └── storage/secure_vault.dart  70  encrypted vault port + Android Keystore
├── features/                       14 features, see §2
├── l10n/
│   ├── app_en.arb            605 keys
│   ├── app_fil.arb           605 keys
│   └── l10n.dart            150   context.l10n + exhaustive enum→string switches
└── shared/widgets/
    ├── common.dart          167   ★ Logo, CardBox, PrimaryButton, Eyebrow, SampleTag, IconTile
    ├── character.dart       167   ★ the Tol mascot SVG and its 4 poses
    ├── form_widgets.dart    178   FormPage, PasswordField, LoadingButton, InlineMessage
    ├── animations.dart       87   FadeSlideIn, Pressable
    └── scenes.dart           22   Scene enum: home / alert / guide / map

test/                       16 files, 174 tests — see §5; fixtures/ holds the PSGC provenance fixture
android/                    app manifest, Gradle, launcher icon, splash
assets/
├── data/                   qc_boundary.json (306 pts), qc_barangays.json (142, PSGC
│                           cross-checked), evacuation_centers_dev.json (6, unverified)
├── fonts/                  DM Sans + Fraunces variable fonts (OFL)
└── guidebook/guidebook.json    5 categories, currently 0 sections
datasets/                   bundled PMTiles, 77 MB (qc_base + qc_flood) — MAP_OPTIONS §4a
supabase/
├── migrations/             3 SQL files — profiles, delete account, sync records
└── functions/              tol-route/index.ts, tol-chat/index.ts
tools/psgc_crosscheck/      crosscheck.py — checks qc_barangays against the official PSGC fixture
docs/                       README, ARCHITECTURE, STRUCTURE, SETUP, ROADMAP, TEST_REPORT,
                            TOL_AI_OPTIONS, MAP_OPTIONS, SHELTER_RANKING_ML
```

★ = the two highest-leverage UI files.

**Largest files** — worth knowing before you open them:

| Lines | File |
|---|---|
| 503 | `features/safe_places/presentation/safe_places_screen.dart` |
| 401 | `features/settings/settings_screen.dart` |
| 337 | `features/household/presentation/household_forms.dart` |
| 333 | `features/onboarding/onboarding_screen.dart` |
| 326 | `features/tol/presentation/tol_chat_screen.dart` |
| 326 | `features/prepare/presentation/prepare_screen.dart` |

---

## 2. "I want to change…"

### Visual design

| Change | File | Anchor |
|---|---|---|
| Brand colors | `lib/core/theme.dart` | `AppColors` :6 |
| Spacing scale | `lib/core/theme.dart` | `AppSpacing` :37 |
| Corner radii | `lib/core/theme.dart` | `AppRadii` :47 |
| Icon sizes | `lib/core/theme.dart` | `AppIconSizes` :56 |
| Animation speed | `lib/core/theme.dart` | `AppDurations` :63 |
| Body type style | `lib/core/theme.dart` | `sans()` :73 |
| Heading type style | `lib/core/theme.dart` | `serif()` :91 |
| Buttons, inputs, dialogs, snackbars, checkboxes, page transitions | `lib/core/theme.dart` | `buildAppTheme()` :107 |
| Logo / wordmark | `lib/shared/widgets/common.dart` | `Logo` :7 |
| Card, button, pill, icon tile | `lib/shared/widgets/common.dart` | `CardBox` :69, `PrimaryButton` :93 |
| The Tol mascot, its poses, **its colors** | `lib/shared/widgets/character.dart` | `_characterSvg()` :11 |
| Mascot poses available | `lib/shared/widgets/scenes.dart` | `Scene` enum |
| Text inputs, bottom sheets | `lib/shared/widgets/form_widgets.dart` | |
| Entrance animation, press feedback | `lib/shared/widgets/animations.dart` | `FadeSlideIn` :7, `Pressable` :58 |

### Layout / navigation

| Change | File |
|---|---|
| Tab bar icons or order | `lib/app/app_shell.dart` :187 |
| Header (logo, offline icon, bell, avatar) | `lib/app/app_shell.dart` :112 |
| Tab content frame, page padding | `lib/app/app_shell.dart` :57 |
| Floating Tol button | `lib/app/app_shell.dart` :41 |
| Any screen | `lib/features/*/presentation/` |
| Add a route | `lib/app/router.dart` |
| Auth gating rules | `lib/app/router.dart` :29 `redirectFor()` |

### Readiness and scoring

| Change | File | Anchor |
|---|---|---|
| **Readiness weights** (currently 40/30/15/15) | `lib/features/readiness/domain/readiness.dart` | `ReadinessReport.weights` :33 |
| Contacts needed for full marks | same | `targetContacts` :40 |
| Water/food coverage maths | `lib/features/supplies/domain/supplies.dart` | `computeSupplyReport()` :195 |
| Litres & meals per person per day (3.8 L / 3) | same | `PreparednessTargets` :32 |
| Score component weights | same | `SupplyReport` :172 |
| "Expiring soon" window (30 days) | same | `expiringSoonDays` :193 |
| Suggestion rules | `lib/features/readiness/domain/recommendations.dart` | |

### Checklist, supplies, household

| Change | File | Anchor |
|---|---|---|
| Go-bag template items (26) | `lib/features/prepare/domain/checklist.dart` | `goBagTemplates` :17 |
| Which items appear per household need | same | `buildChecklist()` :139 |
| Supply categories (7) and units (11) | `lib/features/supplies/domain/supplies.dart` | `SupplyCategory`, `SupplyUnit` |
| Household / contact fields | `lib/features/household/domain/models.dart` | |

### Maps and location

| Change | File | Anchor |
|---|---|---|
| Basemap choice (hosted vs bundled offline) | `lib/features/safe_places/data/map_style.dart` | `BasemapStyle.current` |
| Hazard archive URL + `pmtiles://` scheme | `lib/features/safe_places/data/map_style.dart` | `noahHazardArchive` |
| **Hazard groups and severity scales** | `lib/features/safe_places/domain/hazard.dart` | `HazardGroup`, `severityBands` |
| Hazard layer specs, opacity ramp, layer ids | `lib/features/safe_places/data/hazard_layer_service.dart` | `hazardLayerSpecs()` |
| Which hazard is overlaid (app state) | `lib/features/safe_places/data/hazard_layer_service.dart` | `hazardOverlayProvider` |
| Adding the overlay to the map | `lib/features/safe_places/presentation/map_view.dart` | `_syncHazard()` |
| Hazard band colour + severity filter | `lib/features/safe_places/data/hazard_layer_service.dart` | `hazardFilterExpression()` |
| PMTiles protocol registration (web only) | `lib/features/safe_places/data/hazard_protocol*.dart` | conditional import; never throws |
| Is the hazard overlay usable at all? | `lib/features/safe_places/data/hazard_layer_service.dart` | `hazardLayerStatusProvider` |
| Hazard picker sheet + legend card | `lib/features/safe_places/presentation/safe_places_screen.dart` | `_pickHazard()`, `_HazardLegendCard` |
| The bundled hazard and basemap data itself | `datasets/qc_flood.pmtiles`, `qc_base.pmtiles` | 77 MB, committed on purpose |
| Map tile style | `lib/features/safe_places/data/map_style.dart` | `BasemapStyle` |
| Evacuation centres | `assets/data/evacuation_centers_dev.json` | all 6 are `verified: false` |
| QC boundary / barangay list | `assets/data/qc_boundary.json`, `qc_barangays.json` | |
| Barangay names/codes vs the PSA list | `tools/psgc_crosscheck/crosscheck.py` + `test/fixtures/psgc_qc_official.json` | run `--check` after any data edit |
| Point-in-polygon test | `lib/features/safe_places/domain/qc_area.dart` :15 `contains()` |
| Offline map download size & status | `lib/features/safe_places/data/offline_map_service.dart` | |
| Route service, wheelchair profile | `lib/features/safe_places/data/route_service.dart` | |
| Location permission handling | `lib/features/safe_places/data/location_service.dart` | |
| Map widget / camera control | `lib/features/safe_places/presentation/map_view.dart` | `mapViewBuilderProvider` :32 |

### Text and validation

| Change | File |
|---|---|
| **Any user-facing string** | `lib/l10n/app_en.arb` **and** `lib/l10n/app_fil.arb` — both |
| Show a stored error to the user | `lib/l10n/l10n.dart` (exhaustive switch, no default) |
| Email / phone / password rules | `lib/core/validation.dart` |

### Platform config

| Change | File |
|---|---|
| App name, permissions, deep links | `android/app/src/main/AndroidManifest.xml` |
| Application ID, Java version, signing | `android/app/build.gradle.kts` |
| Gradle memory / workers | `android/gradle.properties` |
| Splash screen background | `android/app/src/main/res/values/colors.xml` + `drawable/launch_background.xml` |
| Launcher icon | `android/app/src/main/res/mipmap-*/` |
| Web page title, meta | `web/index.html`, `web/manifest.json` |
| Supabase URL + key | `env.json` (copy from `env.example.json`) |
| Font families | `assets/fonts/` and `pubspec.yaml` :44 |

### Backend

| Change | File |
|---|---|
| DB tables, RLS policies | `supabase/migrations/*.sql` |
| Walking/wheelchair routing | `supabase/functions/tol-route/index.ts` |
| Tol AI provider, prompt, limits | `supabase/functions/tol-chat/index.ts` |
| Which AI provider is used | `TOL_PROVIDER` secret, not code |

---

## 3. Four traps

**1. The token system is not total.** Hardcoded hex values exist outside `theme.dart`:

- `app_shell.dart` — muted grey `#5C6B63` at lines 81, 176, 229, 240; guest-amber `#7A521A` at 101, 105; avatar colours at 148, 150, 152
- `common.dart` :59 (`Eyebrow`), :135 (`SampleTag`)
- `alerts/presentation/alert_card.dart` — 15 hardcoded hex values

Changing `AppColors.muted` will leave those untouched. Grep before assuming a colour change went everywhere.

**2. The mascot has its own palette.** `character.dart` :17-43 hardcodes `#3f5d51`, `#a3c4a5`, `#f7e9cf`, `#719b7b` etc. inside the SVG `StringBuffer`. Recolouring `AppColors` does nothing to Tol — you must edit that buffer.

**3. `PrimaryButton` bypasses the theme.** `common.dart` :93 sets `color: AppColors.sage` directly instead of reading `Theme.of(context)`, so changes to `filledButtonTheme` in `theme.dart` will not reach it.

**4. Text must go in both ARB files.** `lib/l10n/l10n.dart` uses exhaustive `switch` expressions with no `default`, so a missing key is a **compile error**, not a runtime `undefined`. Both `app_en.arb` and `app_fil.arb` must be updated.

---

## 4. Adding things

**New screen** — create in `lib/features/<name>/presentation/` → register in `lib/app/router.dart` → add strings to both ARB files.

**New string** — add to `app_en.arb` and `app_fil.arb`, then `flutter gen-l10n` (or just run the app; it regenerates). Reference as `context.l10n.yourKey`.

**New provider** — Riverpod, no codegen. Put `Notifier`/`AsyncNotifier` providers in the feature's `application/` layer, derived `Provider`s alongside. See `lib/features/readiness/application/readiness_providers.dart` :13-47 for the pattern — derived providers return `null` while any source is loading (see the comment at :32).

**New port** (a swappable external dependency) — declare `abstract interface class` in the feature's `data/`, bind an implementation in a `Provider`, and add an `Unconfigured*` fallback that fails with a real error code rather than silently doing nothing. See `lib/features/safe_places/data/route_service.dart` :101.

**New database table** — edit `lib/core/database/app_database.dart`, then `dart run build_runner build`.

---

## 5. Verifying a change

```bash
flutter test --concurrency=1     # 174 tests; --concurrency=1 is mandatory
flutter analyze                  # must be clean
```

Two tests specifically guard UI work:

- **`test/responsive_test.dart`** — every route at 320×568 and 320×2400, in Filipino, at large text. Run this after any layout change.
- **`test/accessibility_test.dart`** — 48 dp tap targets, semantic labels, WCAG AA contrast. Run this after any colour or sizing change.

Others worth knowing: `unit_test.dart` (readiness weights, coverage maths, redirects), `error_states_test.dart`, `phase4_test.dart` (guidebook content guard), `hazard_layer_test.dart` (overlay specs, filters, legend wording), `qc_area_test.dart` (PSGC fixture match).

**Global UI chokepoints** — set these once, not per screen:

- Motion: `lib/core/theme.dart` :70 `motion(context, duration)` → returns `Duration.zero` under reduced motion
- Text size and reduced motion are applied in `lib/main.dart` `builder:` for the whole app
- All new animations must go through `motion()`, or reduced-motion users lose them

---

## 6. Backend map

| File | Owns |
|---|---|
| `migrations/20261018000000_profiles.sql` | `profiles` table, RLS, `handle_new_user()`, `touch_updated_at()` |
| `migrations/20261019000000_delete_own_account.sql` | `delete_own_account()` RPC |
| `migrations/20261020000000_sync_records.sql` | `sync_records`, RLS, `sync_push()` — the conflict rule in SQL |
| `functions/tol-route/index.ts` | Proxies OpenRouteService; holds `ORS_API_KEY`; walking + wheelchair; Metro Manila bounds check |
| `functions/tol-chat/index.ts` | Tol AI; `TOL_PROVIDER`; strips 7+ digit numbers from replies |

Secrets live server-side only: `ORS_API_KEY`, `TOL_PROVIDER`, `TOL_MODEL`,
`ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `OPENAI_API_KEY`, `TOL_SHARE_CONTEXT`.

Never put any of these in `env.json` — anything compiled into the APK can be extracted.

---

## 7. Do not edit

Generated or machine-owned files. Edits are lost on the next build.

| Path | Regenerate with |
|---|---|
| `lib/l10n/generated/` (8,142 lines) | `flutter gen-l10n` — **do not edit** |
| `lib/core/database/app_database.g.dart` | `dart run build_runner build` |
| `android/app/src/main/java/**/GeneratedPluginRegistrant.java` | automatic |
| `build/`, `.dart_tool/`, `.flutter-plugins-dependencies` | automatic |
| `android/local.properties` | machine-local SDK paths, git-ignored |
| `web/vendor/pmtiles-4.3.0.js` | third-party, BSD-3-Clause — re-download to update, don't hand-edit |
| `env.json` | git-ignored; copy from `env.example.json` |

The generated localizations are **committed** on purpose — the app builds without a codegen
step, which matters on an 8 GB machine.

---

## 8. Known gaps

Same list as `ARCHITECTURE.md` §15, repeated here so you don't trust a file you haven't read.

- No Supabase project provisioned — migrations and functions are written but never run live
- `applicationId` is still `com.example.tolong_flutter` (`build.gradle.kts` :19, TODO in file)
- Release builds sign with the **debug** key (`build.gradle.kts` :36, TODO in file)
- Guidebook has **0 sections** — the parser drops uncited content on purpose
- Evacuation centres are unverified demo data
- iOS unconfigured; Android is the only target