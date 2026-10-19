# TolongApp — Code Guide

Calm, offline-first disaster preparedness for every household.

This document explains **how the code is organised and why**, and doubles as the
lookup: **"I want to change X → open these files."** It is the map a new
contributor reads before their first change. For setup steps see
[`tolong_flutter/docs/SETUP.md`](SETUP.md); for status and gaps see
[`tolong_flutter/docs/STATUS.md`](STATUS.md); the design options behind the map
and the AI assistant live in [`design/`](design/).

---

## 1. Repository shape

| Path | What it is |
|---|---|
| `tolong_flutter/` | **The TolongApp product** — Flutter, Android-first. All feature work happens here. |
| `tolong_flutter/supabase/` | Postgres migrations + 2 Deno Edge Functions (Deno/TypeScript, client-agnostic). |
| `tolong_flutter/docs/` | Setup, code guide, status, change history, and design-option notes. |

Every path below is relative to `tolong_flutter/` unless stated otherwise.

---

## 2. Tech stack

| Concern | Choice | Notes |
|---|---|---|
| Language / UI | Dart ^3.5.0, Flutter | Android first; web is a secondary build target |
| State | `flutter_riverpod` ^3.4.3 | **No code generation.** Deliberate — `build_runner` on an 8 GB laptop is slow. |
| Routing | `go_router` ^18.1.0 | Declarative, `StatefulShellRoute` for tabs |
| Backend | `supabase_flutter` ^2.18.3 | Auth + Postgres + Edge Functions |
| Local secrets | `flutter_secure_storage` ^11.2.0 | Android Keystore |
| Non-sensitive prefs | `shared_preferences` ^2.5.6 | Settings flags only |
| Sync bookkeeping | `drift` ^2.35.2, `drift_flutter` ^0.3.1 | SQLite, **metadata only** |
| Maps | `maplibre_gl` ^0.27.1 | Vector map + offline region download; web loads a **vendored** PMTiles loader from `web/vendor/` (no CDN on the boot path) |
| Location | `geolocator` ^14.1.1 | |
| Local file access | `path_provider` ^2.1.6 | Extracts the hazard archive into app storage (Android/iOS) |
| Alerts | `audioplayers` ^6.1.0 | Flood warning tone |
| i18n | `flutter_localizations` + ARB | English + Filipino, 622 keys each |
| Tests | `flutter_test`, `flutter_lints` ^4.0.0 | 195 passing |

Gradle is deliberately throttled (`android/gradle.properties`: 1536 MB heap, 2 workers,
parallel off) because the dev machines have 8 GB RAM.

---

## 3. Architectural pattern: feature-first clean architecture with swappable ports

Each feature under `lib/features/` owns a vertical slice and splits it into up to four
layers:

```
presentation/   widgets and screens only
     ↓           calls providers, renders state
application/    Riverpod notifiers/controllers — orchestration
     ↓           calls repositories and services
domain/         pure Dart: models, formulas, rules — zero framework imports
     ↑
data/           repository + service implementations (ports & adapters)
```

**The dependency rule is real and mechanically checkable:** files in `domain/` import only
`dart:*` and other features' `domain/` files. No Flutter, no Supabase. That is what makes
the readiness maths, supply coverage and conflict rules testable without a widget tree.

Small features collapse layers — `home`, `more`, `alerts`, `offline`, `settings` have no
`domain/` because they have no rules worth isolating. A missing layer is a deliberate
signal, not an oversight.

### The port pattern

Every non-deterministic dependency is declared as an `abstract interface class` and bound to
an implementation by a Riverpod provider. There are eight ports:

| Port | Real implementation | Fallback |
|---|---|---|
| `SecureVault` | `DeviceSecureVault` (Android Keystore) | `MemoryVault` |
| `AuthRepository` | `SupabaseAuthRepository` | `UnconfiguredAuthRepository` |
| `RouteService` | `EdgeFunctionRouteService` | `UnavailableRouteService` |
| `OfflineMapService` | `MapLibreOfflineMapService` | — |
| `LocationService` | `GeolocatorLocationService` | — |
| `SyncRemote` | `SupabaseSyncRemote` | `null` (sync disabled) |
| `OnlineTolService` | Edge Function client | offline rule-based guide |
| `MapHandle` / `MapViewBuilder` | `MapLibreMap` widget (optional `onHazardDrawState` callback) | `FakeMap` in tests |

Two of these bindings are the backbone of the whole test strategy:

- **`mapViewBuilderProvider`** (`lib/features/safe_places/presentation/map_view.dart:32`) —
  platform map views do not render in `flutter_test`, so the map is reached only through
  this indirection and tests swap in `FakeMap`.
- **`clockProvider`** (`lib/core/clock.dart`) — an injectable `DateTime Function()` so every
  expiry, greeting and "days covered" calculation is deterministic.

Provider selection frequently branches on configuration:

```dart
final routeServiceProvider = Provider<RouteService>(
  (ref) => Env.supabaseConfigured ? EdgeFunctionRouteService() : UnavailableRouteService(),
);
```

### Errors cross boundaries as codes, never as text

`AuthErrorCode`, `RouteErrorCode`, `TolErrorCode`, and `SyncFailure(String code)` travel
across every layer. `lib/l10n/l10n.dart` maps each code to a localized string in an
exhaustive `switch` with **no default arm**. Consequences:

- The UI never displays server-provided English text.
- Adding an enum value is a compile error until it is translated — you cannot forget a locale.
- Tests assert on codes, which survive copy changes.

---

## 4. Local-first, dual store

This is the single most important design decision in the codebase, and the most
counter-intuitive one. The app is fully usable with no backend, no network, and no account.

### Store A — encrypted JSON documents (the source of truth)

`SecureVault` (`lib/core/storage/secure_vault.dart`) is an encrypted key-value store.
Records are JSON blobs keyed `'<kind>:<owner>'`, where `owner` is either the Supabase user
id or the literal `"guest"` (`lib/features/auth/application/session.dart:9`). That means a
guest profile and a signed-in account can coexist on one phone without colliding.

| Repository | Vault keys |
|---|---|
| `HouseholdRepository` | `profile`, `household`, `contacts:<owner>` |
| `SuppliesRepository` | `supplies:<owner>` |
| `ChecklistRepository` | `checklist:<owner>` |
| `TolHistoryRepository` | `tol:<owner>` (last 60 messages) |

`SecureSessionStorage` (`secure_vault.dart:47`) also overrides Supabase's session storage so
the auth token lands in the Keystore instead of plain SharedPreferences.

### Store B — Drift/SQLite, bookkeeping only

`lib/core/database/app_database.dart` defines three tables — `SyncQueue`, `RecordVersions`,
`SyncStates` — and **the queue rows hold only *which* record changed, never its contents**:

```dart
/// One pending change per record. Rows hold only *which* record changed, never its contents,
/// so no personal data sits in this (unencrypted) SQLite file; the encrypted vault stays the
/// source of truth and is read at push time.
```

At push time the sync engine reads the actual record out of the encrypted vault
(`sync_engine.dart:44`). This is why the app can ship a plain SQLite file without leaking a
user's household composition, evacuation plans or medical details to anyone with physical
access to an unlocked handset.

`build.yaml` sets `store_date_time_values_as_text: true` so timestamps persist as ISO-8601
text. The conflict rule compares timestamps across devices, and SQLite's integer date
storage would lose the millisecond precision it depends on.

### Write path

Repositories write to the encrypted vault **synchronously**, then enqueue a sync marker
fire-and-forget. The UI updates instantly and never waits on the network. Ordering is
guaranteed because the durable write happens first.

---

## 5. Sync

`lib/features/sync/` — 5 files, deliberately small.

- **`domain/sync_types.dart`** — `SyncEntity` enum (names are stored on the server, never
  rename them), `RemoteRecord`, and the two pure functions that define sync behaviour.
- **`data/sync_store.dart`** — Drift queue, coalesced by primary key `(owner, entity, recordId)`
  so rapid edits collapse into one push. Deletions become tombstones rather than row removal.
- **`data/sync_remote.dart`** — Supabase transport behind the `SyncRemote` port.
- **`application/sync_engine.dart`** — the `SyncEngine.run(owner)` push/pull loop plus the
  `SyncController` that owns lifecycle, debouncing and reactive invalidation.

### The conflict rule

```dart
/// a pulled record replaces the local one only if it was changed later than the local copy
/// and later than any local change still waiting to be pushed. Ties keep the local copy,
/// which is then pushed and settles the tie on the server.
bool shouldApplyRemote({required DateTime remote, DateTime? local, DateTime? pending}) {
  if (pending != null && !remote.isAfter(pending)) return false;
  if (local != null && !remote.isAfter(local)) return false;
  return true;
}
```

The same rule is implemented in SQL inside `sync_push` (`supabase/migrations/20261020000000_sync_records.sql`).
`FakeSyncRemote` in the test suite re-implements it in Dart a third time — deliberately, so
the test verifies the *rule is consistent* rather than that a fake agreed with itself.

Failed pushes back off via `retryDelay()`: 30 s, doubling, capped at 1 hour. Coalescing
means a user editing ten supplies in a row produces one network round-trip.

After a pull that changed anything, the controller invalidates three providers together
(`sync_engine.dart:194`):

```dart
ref..invalidate(householdProvider)
   ..invalidate(suppliesProvider)
   ..invalidate(checklistStateProvider);
```

Sync is disabled entirely — not merely made to fail — when running on web, when
`syncRemoteProvider` is null, or when no one is signed in (`sync_engine.dart:155`).

---

## 6. Domain logic worth reading

Three computations are the product's actual substance. All are pure and directly tested.

### Readiness score (0–100)

`lib/features/readiness/domain/readiness.dart:33`

| Area | Weight | Progress |
|---|---|---|
| Go-bag checklist | 40% | items done ÷ total |
| Supply coverage | 30% | from `computeSupplyReport()` |
| Emergency contacts | 15% | ≥ 2 contacts = full |
| Household profile | 15% | 0.5 saved + 0.5 barangay set |

Weights are a `static const` map, so the score is auditable by reading one literal — no
hidden coefficients.

### Supply coverage

`lib/features/supplies/domain/supplies.dart:172`

Score is **water 30% + food 30% + 10% per present essential category** (medicine, first
aid, hygiene, lighting).

- Water days = usable litres ÷ (household size × 3.8 L/person/day)
- Food days = usable meals ÷ (household size × 3 meals/person/day)
- Expired items are excluded from `usable`
- `expiringSoonDays = 30`

**Items whose per-unit amount is unknown are counted and reported, never guessed.** A
household that typed "rice" without a quantity gets an honest `unknownItems` entry instead
of a fabricated number feeding the score.

### Point-in-polygon

`lib/features/safe_places/domain/qc_area.dart:15` — ray-casting against the bundled QC
boundary. Implemented by hand to keep `domain/` free of the `geometry` package.

---

## 7. Routing

`lib/app/router.dart` — go_router 18, two patterns.

**Tab shell.** `StatefulShellRoute.indexedStack` with four branches (`/home`, `/prepare`,
`/safe-places`, `/more`), each wrapped by a `_tab(path, index, child)` helper producing a
`TabPage`. The indexed stack preserves per-tab scroll position when switching tabs.

**Auth gating as a pure function.** This is the pattern to copy when adding routes:

```dart
/// Pure routing decision so it can be unit tested without widgets.
@visibleForTesting
String? redirectFor(SessionState s, String location) {
  if (!s.ready) return location == '/splash' ? null : '/splash';
  if (s.recoveringPassword) return location == '/reset-password' ? null : '/reset-password';
  if (!s.signedIn && !s.guest) return _publicRoutes.contains(location) ? null : '/welcome';
  if (s.signedIn && !s.onboardingComplete) return location == '/onboarding' ? null : '/onboarding';
  ...
}
```

Because it takes a `SessionState` and returns a `String?` with no `BuildContext`, the
entire auth state machine is unit-tested in `unit_test.dart` with no widget pump.

Router refresh is driven by `ref.listen(sessionProvider)` incrementing a `ValueNotifier<int>`
passed as `refreshListenable` — the standard go_router + Riverpod bridge.

### AppShell

`lib/app/app_shell.dart` composes the chrome: a 480 dp `ConstrainedBox` (centres content on
web and tablets), guest banner, header (logo, offline status → `/offline-readiness`, bell,
avatar → `/profile`), the floating **TolFab**, and the bottom nav.

Two details worth preserving if you touch it:

- The TolFab is hidden when `shell.currentIndex == 2` (Safe Places) so it never covers map
  controls.
- `TabPage` renders a `ListView` with 88 px bottom padding so the FAB never hides the last
  row of content.

---

## 8. Feature map

`lib/features/` — 14 features. Layers omitted where a feature has no rules to isolate.

| Feature | Layers | Responsibility |
|---|---|---|
| `auth` | a/d/p | Email/password auth, onboarding entry, guest mode, privacy notice, password recovery |
| `household` | d/p | `UserProfile`, `HouseholdProfile`, `EmergencyContact` as encrypted docs |
| `supplies` | d/p | Inventory: 7 categories, 11 units, expiry, coverage maths |
| `prepare` | d/p | Go-bag checklist: 26 stable-id templates + 7 household-specific suggestions |
| `readiness` | a/p | Weighted score, per-area breakdown, rule-based recommendation agent |
| `safe_places` | a/d/p | MapLibre map, GPS, evacuation centres, QC boundary, barangay search, routing, offline map, navigation, NOAH hazard overlay |
| `sync` | a/d/p | Drift queue, engine, remote, store, conflict rules |
| `tol` | a/d/p | AI assistant — Edge Function online, rule-based offline fallback, encrypted history |
| `guidebook` | d/p | Bundled offline guide (structure only, see §11) |
| `settings` | — | Preferences, local-data wipe, account deletion |
| `home` | — | Dashboard |
| `more` | — | Tab hub |
| `onboarding` | — | 5-step wizard |
| `alerts` | — | Flood alert card + warning sound |
| `offline` | — | Offline Readiness Center |

### The NOAH hazard overlay (`safe_places`)

`datasets/qc_flood.pmtiles` holds nine modelled-hazard layers, shown to users as four
groups: flood depth, landslide, storm surge, debris flow. The pieces, in dependency order:

- **`domain/hazard.dart`** — groups and severity bands. Codes are **ints**: the archive stores
  `Var`/`HAZ` as numbers, and MapLibre's `==`/`in` are type-strict, so a string code silently
  matches nothing (a legend with no colours and no error).
- **`data/hazard_layer_service.dart`** — pure layer specs (one fill layer per severity band),
  `hazardFilterExpression()`, and `HazardDrawState` + `classifyDraw()`, the "did anything
  actually draw?" classifier.
- **`data/hazard_archive.dart`** — `prepareHazardArchive()`, awaited once from `main()`. Web
  registers the archive with the vendored PMTiles loader (`web/vendor/hazard_archive.js`
  fetches it as one whole file — the dev server cannot byte-serve); Android/iOS extract it
  into the app-support directory. Returns `null` on any failure; start-up never blocks on it.
- **`data/map_style.dart`** — `hazardArchiveKey`, the single constant behind both the
  registered key and the map's `pmtiles:///…` source URL (three slashes — the library strips
  exactly the scheme's length).
- **`presentation/map_view.dart`** — `_syncHazard()` adds/rebinds the layers on style load;
  `onMapIdle` runs the draw check so a filter that matches nothing surfaces as a legend note
  (`hazardNothingDrawn`) instead of a silently colourless map.

Data provenance, tile anatomy and the licence caveat:
[`design/MAP_OPTIONS.md`](design/MAP_OPTIONS.md) §4a.

---

## 9. Backend

`tolong_flutter/supabase/` — no server framework; both functions are raw `Deno.serve`.

### Migrations

| File | Contents |
|---|---|
| `20261018000000_profiles.sql` | `profiles` table, RLS policies, `handle_new_user()` trigger, `touch_updated_at()` |
| `20261019000000_delete_own_account.sql` | `delete_own_account()` RPC — account deletion without a service-role key |
| `20261020000000_sync_records.sql` | `sync_records` table, RLS, `sync_push(jsonb)` implementing the conflict rule in SQL |

Every table is RLS-protected with `*_own` policies. The client only ever holds the
publishable (anon) key.

### `tol-route`

Proxies OpenRouteService so the ORS key never ships in the APK.

- Accepts only `foot-walking` and `wheelchair`
- Rejects coordinates outside a Metro Manila bounding box — the app supports Quezon City
  only, and this also protects the shared free quota
- Per-IP burst limit, 10 requests/minute (best-effort; the ORS daily quota is the hard cap)
- Maps upstream ORS codes 2004/2009/2010/2099 to a single `no_route` error code

### `tol-chat`

Provider-agnostic Tol assistant — switch with `TOL_PROVIDER` (`anthropic`, `gemini`,
`openai`) without an app release.

- JWT verification stays **on**: only signed-in users can reach Tol online
- 25 s upstream timeout; 20 requests per 10 min per user
- Input caps: 12 messages × 1000 chars, 6000 chars total
- A system prompt forbids inventing hazards, routes or hotlines
- `guardOutput()` strips **any 7+ digit number** from the reply, so an invented hotline can
  never reach a user in an emergency. (911 is under 7 digits and survives.)
- `TOL_SHARE_CONTEXT=false` drops household context entirely, for providers that train on
  free-tier traffic

---

## 10. Configuration and secrets

Only **two** compile-time values are injected into the app:

```json
// env.json — copy from env.example.json, git-ignored
{ "SUPABASE_URL": "...", "SUPABASE_PUBLABLE_KEY": "..." }
```

supplied via `--dart-define-from-file=env.json` and read in `lib/core/config/env.dart`.

`env.dart` carries an explicit warning: **never put a service-role key or an AI provider key
here.** Anything compiled into an APK can be extracted. All real secrets are Supabase
function secrets (`ORS_API_KEY`, `TOL_PROVIDER`, `ANTHROPIC_API_KEY`, …).

The deep-link scheme is `io.tolongapp://login-callback`, which must also be registered under
Supabase → Authentication → URL Configuration → Redirect URLs.

**There are no Dart `--define` build flavors.** Environment differentiation happens entirely
at runtime through `Env.supabaseConfigured`. `main.dart` initialises Supabase only if it is
configured, and the app runs fully offline otherwise.

---

## 11. Honesty as a design constraint

A recurring, deliberate theme — an app about emergencies must not fake capability.

- **`SampleTag`** (`lib/shared/widgets/common.dart`) — labels placeholder content
  "SAMPLE DATA" / "NOT REAL DATA".
- **`Unconfigured*` repositories** — fail with a specific error code rather than silently
  degrading to a no-op.
- **`showSoon(context, …)`** — unfinished buttons say so instead of doing nothing.
- **Unverifiable guidebook content is dropped at parse time.** `assets/guidebook/guidebook.json`
  currently has 5 categories and **0 sections**, because no section has a citable source yet.
  The parser refuses to render uncited advice.
- **`evacuation_centers_dev.json`** carries 6 centres all flagged `verified: false`.

The Phase 1 checklist in [`CHANGELOG.md`](CHANGELOG.md) lists this as an explicit
deliverable, and `accessibility_test.dart` + `phase4_test.dart` guard it with tests.

---

## 12. Accessibility and motion

These are global chokepoints, not per-screen concerns. Set them once in `main.dart`.

**Motion.** `motion(context, duration)` in `lib/core/theme.dart` returns `Duration.zero`
under reduced motion. `FadeSlideIn` uses an `Interval` curve for its delay rather than a
`Timer` so it renders immediately when animation is disabled. `MaterialApp.router.builder`
combines the OS setting with the in-app `settings.reducedMotion`.

**Text size.** The user multiplier is applied once, in the same `builder`, rather than at
every text site.

**Contrast.** `AppColors` is tuned to WCAG AA; sage was deepened from `#63896D` to `#52775D`
specifically so white button text passes. `Logo` sets `textScaler: noScaling` so the brand
mark stays a fixed size at large text settings.

`responsive_test.dart` exercises every route at 320×568 and 320×2400, in Filipino, at large
text.

---

## 13. File map

The Flutter app is `tolong_flutter/`. The Supabase backend is `tolong_flutter/supabase/`.
Both `flutter` and `flutter test` must be run from inside `tolong_flutter/` — the repo
root holds only `tools/`. Every `lib/…` path below is relative to `tolong_flutter/`.

At the repo root:

```
tools/psgc_crosscheck/      crosscheck.py — checks qc_barangays against the official PSGC fixture
tools/hazard_archive_check/ hazard_fields.py — pins the archive's attribute fields (Var/HAZ as
                            numbers, observed values) to test/fixtures/hazard_archive_fields.json
```

Inside `tolong_flutter/`:

```
pubspec.yaml                  dependencies + assets + fonts
analysis_options.yaml         lint rules (flutter_lints)
build.yaml                    drift codegen config
l10n.yaml                     ARB → lib/l10n/generated/
env.example.json              template for env.json (git-ignored)

lib/
├── main.dart                 87   entry: boots Supabase, prepares the hazard archive,
│                                  ProviderScope, TolongApp
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
├── features/                       14 features — see the feature map (§8)
├── l10n/
│   ├── app_en.arb            622 keys
│   ├── app_fil.arb           622 keys
│   └── l10n.dart            167   context.l10n + exhaustive enum→string switches
└── shared/widgets/
    ├── common.dart          167   ★ Logo, CardBox, PrimaryButton, Eyebrow, SampleTag, IconTile
    ├── character.dart       167   ★ the Tol mascot SVG and its 4 poses
    ├── form_widgets.dart    178   FormPage, PasswordField, LoadingButton, InlineMessage
    ├── animations.dart       87   FadeSlideIn, Pressable
    └── scenes.dart           22   Scene enum: home / alert / guide / map

test/                       17 files, 195 tests — inventory in STATUS.md;
                            fixtures/ holds the PSGC provenance fixture and the
                            hazard archive field fixture
android/                    app manifest, Gradle, launcher icon, splash
assets/
├── data/                   qc_boundary.json (306 pts), qc_barangays.json (142, PSGC
│                           cross-checked), evacuation_centers_dev.json (6, unverified)
├── fonts/                  DM Sans + Fraunces variable fonts (OFL)
└── guidebook/guidebook.json    5 categories, currently 0 sections
datasets/                   bundled PMTiles, 77 MB (qc_base + qc_flood) — design/MAP_OPTIONS.md §4a
supabase/
├── migrations/             3 SQL files — profiles, delete account, sync records
└── functions/              tol-route/index.ts, tol-chat/index.ts
web/                        index.html + vendored PMTiles loader and archive glue (vendor/)
docs/                       SETUP, CODE_GUIDE, STATUS, CHANGELOG; design/ = MAP_OPTIONS,
                            TOL_AI_OPTIONS, SHELTER_RANKING_ML
```

★ = the two highest-leverage UI files.

**Largest files** — worth knowing before you open them:

| Lines | File |
|---|---|
| 663 | `features/safe_places/presentation/safe_places_screen.dart` |
| 401 | `features/settings/settings_screen.dart` |
| 337 | `features/household/presentation/household_forms.dart` |
| 333 | `features/onboarding/onboarding_screen.dart` |
| 326 | `features/tol/presentation/tol_chat_screen.dart` |
| 326 | `features/prepare/presentation/prepare_screen.dart` |

---

## 14. "I want to change…"

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
| Numeric codes the filter compares against | `tools/hazard_archive_check/hazard_fields.py` + `test/fixtures/hazard_archive_fields.json` | run `--check` after any dataset change |
| Did the overlay actually draw? (silent-failure pin) | `lib/features/safe_places/data/hazard_layer_service.dart` | `HazardDrawState` + `classifyDraw()` |
| PMTiles protocol registration (web only) | `lib/features/safe_places/data/hazard_protocol*.dart` | conditional import; never throws |
| Archive preparation per platform (web register, native extract) | `lib/features/safe_places/data/hazard_archive.dart` | `prepareHazardArchive()` — reports `null`, never throws |
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

---

## 15. Four traps

**1. The token system is not total.** Hardcoded hex values exist outside `theme.dart`:

- `app_shell.dart` — muted grey `#5C6B63` at lines 81, 176, 229, 240; guest-amber `#7A521A` at 101, 105; avatar colours at 148, 150, 152
- `common.dart` :59 (`Eyebrow`), :135 (`SampleTag`)
- `alerts/presentation/alert_card.dart` — 15 hardcoded hex values

Changing `AppColors.muted` will leave those untouched. Grep before assuming a colour change went everywhere.

**2. The mascot has its own palette.** `character.dart` :17-43 hardcodes `#3f5d51`, `#a3c4a5`, `#f7e9cf`, `#719b7b` etc. inside the SVG `StringBuffer`. Recolouring `AppColors` does nothing to Tol — you must edit that buffer.

**3. `PrimaryButton` bypasses the theme.** `common.dart` :93 sets `color: AppColors.sage` directly instead of reading `Theme.of(context)`, so changes to `filledButtonTheme` in `theme.dart` will not reach it.

**4. Text must go in both ARB files.** `lib/l10n/l10n.dart` uses exhaustive `switch` expressions with no `default`, so a missing key is a **compile error**, not a runtime `undefined`. Both `app_en.arb` and `app_fil.arb` must be updated.

---

## 16. Do not edit

Generated or machine-owned files. Edits are lost on the next build.

| Path | Regenerate with |
|---|---|
| `lib/l10n/generated/` (8,372 lines) | `flutter gen-l10n` — **do not edit** |
| `lib/core/database/app_database.g.dart` | `dart run build_runner build` |
| `android/app/src/main/java/**/GeneratedPluginRegistrant.java` | automatic |
| `build/`, `.dart_tool/`, `.flutter-plugins-dependencies` | automatic |
| `android/local.properties` | machine-local SDK paths, git-ignored |
| `web/vendor/pmtiles-4.3.0.js` | third-party, BSD-3-Clause — re-download to update, don't hand-edit |
| `env.json` | git-ignored; copy from `env.example.json` |

The generated localizations are **committed** on purpose — the app builds without a codegen
step, which matters on an 8 GB machine.

---

## 17. Verifying a change

```bash
cd tolong_flutter
flutter test --concurrency=1     # 195 tests; --concurrency=1 is mandatory
flutter analyze                  # must be clean
```

Full suite inventory and what is not covered: [`docs/STATUS.md`](STATUS.md).

Two tests specifically guard UI work:

- **`test/responsive_test.dart`** — every route at 320×568 and 320×2400, in Filipino, at large text. Run this after any layout change.
- **`test/accessibility_test.dart`** — 48 dp tap targets, semantic labels, WCAG AA contrast. Run this after any colour or sizing change.

**Global UI chokepoints** — set these once, not per screen:

- Motion: `lib/core/theme.dart` :70 `motion(context, duration)` → returns `Duration.zero` under reduced motion
- Text size and reduced motion are applied in `lib/main.dart` `builder:` for the whole app
- All new animations must go through `motion()`, or reduced-motion users lose them

---

## 18. Adding a feature — the shape of the change

1. **`domain/`** — models and pure functions. No imports. Test first.
2. **`data/`** — repository reading/writing through `SecureVault`. Enqueue via
   `syncProvider.recordChange(entity, id)`.
3. **`application/`** — a `NotifierProvider` exposing the derived state.
4. **`presentation/`** — screens and widgets only.
5. Add strings to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fil.arb`.
6. Add error codes to the exhaustive `switch` in `lib/l10n/l10n.dart`.
7. Register the route in `lib/app/router.dart`.
8. Run `flutter analyze` and `flutter test --concurrency=1`.

When the shape differs from the standard four layers:

- **New provider** — Riverpod, no codegen. Put `Notifier`/`AsyncNotifier` providers in the feature's `application/` layer, derived `Provider`s alongside. See `lib/features/readiness/application/readiness_providers.dart` :13-47 for the pattern — derived providers return `null` while any source is loading (see the comment at :32).
- **New port** (a swappable external dependency) — declare `abstract interface class` in the feature's `data/`, bind an implementation in a `Provider`, and add an `Unconfigured*` fallback that fails with a real error code rather than silently doing nothing. See `lib/features/safe_places/data/route_service.dart` :101.
- **New database table** — edit `lib/core/database/app_database.dart`, then `dart run build_runner build`.

---