# TolongApp — Architecture

Calm, offline-first disaster preparedness for every household.

This document explains **how the code is organised and why**. It is the map a new
contributor reads before their first change. For setup steps see
[`tolong_flutter/docs/SETUP.md`](SETUP.md); for status and gaps see
[`tolong_flutter/docs/ROADMAP.md`](ROADMAP.md).

---

## 1. Repository shape

| Path | What it is |
|---|---|
| `tolong_flutter/` | **The TolongApp product** — Flutter, Android-first. All feature work happens here. |
| `tolong_flutter/supabase/` | Postgres migrations + 2 Deno Edge Functions (Deno/TypeScript, client-agnostic). |
| `tolong_flutter/docs/` | Setup, roadmap, test report, and design/option notes. |

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

Data provenance, tile anatomy and the licence caveat: `MAP_OPTIONS.md` §4a.

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

`docs/ROADMAP.md` §72 lists this as an explicit Phase 1 deliverable, and
`accessibility_test.dart` + `phase4_test.dart` guard it with tests.

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

## 13. Testing

```bash
cd tolong_flutter
flutter test --concurrency=1     # 195 passing; --concurrency=1 is mandatory
flutter analyze                   # clean
```

Parallel test engines exhaust memory on the target machines.

| File | Focus |
|---|---|
| `test_helpers.dart` | `pumpApp()` boots the real `TolongApp` at 360×780; seven fakes |
| `unit_test.dart` | Redirects, validation, coverage maths, readiness weights, checklist merge |
| `tol_test.dart` | Offline intents EN/FIL, **no personal data in AI context**, consent, fallback |
| `qc_area_test.dart` | Boundary, 142 barangays, search, offline tile estimate |
| `routing_test.dart` | Route drawing, wheelchair profile, error codes, off-route/arrival |
| `sync_engine_test.dart` | Coalescing, tombstones, conflict rule, retry backoff |
| `phase2_flows_test.dart` | Checklist, supplies, settings, account deletion |
| `safe_places_test.dart` | Demo labels, markers, outside-QC, location denied/off/blocked |
| `hazard_layer_test.dart` | Overlay specs, numeric severity filters, draw-state classification, legend wording |
| `hazard_archive_fields_test.dart` | Severity codes pinned to values decoded from the bundled archive |
| `phase4_test.dart` | Guidebook uncited-content guard, offline readiness, queued backup |
| `responsive_test.dart` | Every route, two viewports, Filipino, large text |
| `sync_store_test.dart` | Drift queue behaviour |
| `widget_test.dart` | Welcome without a backend, honest errors, guest mode, tabs |
| `onboarding_test.dart` | Onboarding flow |
| `error_states_test.dart` | Unreadable assets, failed download |
| `accessibility_test.dart` | 48 dp tap targets, labels, WCAG AA contrast |

The port indirection pays off here: `test_helpers.dart` overrides `mapViewBuilderProvider`
with `FakeMap`, uses `MemoryVault` instead of the Keystore, an in-memory
`NativeDatabase.memory()`, and a fixed `clockProvider` (`fixedNow = DateTime(2026,10,18,9,30)`).

**Not tested** (per `docs/TEST_REPORT.md`): real Android devices, and everything requiring a
live Supabase project — auth, backup sync, Edge Functions.

---

## 14. Adding a feature — the shape of the change

1. **`domain/`** — models and pure functions. No imports. Test first.
2. **`data/`** — repository reading/writing through `SecureVault`. Enqueue via
   `syncProvider.recordChange(entity, id)`.
3. **`application/`** — a `NotifierProvider` exposing the derived state.
4. **`presentation/`** — screens and widgets only.
5. Add strings to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fil.arb`.
6. Add error codes to the exhaustive `switch` in `lib/l10n/l10n.dart`.
7. Register the route in `lib/app/router.dart`.
8. Run `flutter analyze` and `flutter test --concurrency=1`.

---

## 15. Known gaps

Verify against `docs/ROADMAP.md` before assuming any of these are current.

- **No Supabase project provisioned.** Migrations and functions are written and
  deployable but have never run against a live project.
- **`applicationId` is still `com.example.tolong_flutter`** — must change before release.
- **Release builds are signed with the debug key** (`android/app/build.gradle.kts:36`,
  with a TODO).
- **Guidebook has zero sections** pending cited sources.
- **Evacuation centres are unverified demo data** (6 records, `verified: false`).
- **Phase 6 hazard-aware routing was skipped.**
- **iOS is unconfigured.** Android is the only shipped target; maplibre and geolocator
  permissions are declared for Android only.