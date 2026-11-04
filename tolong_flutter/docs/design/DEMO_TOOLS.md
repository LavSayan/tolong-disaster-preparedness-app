# Demo / admin tools

Written 2026-10-25. Companion to [`STATUS.md`](../STATUS.md) and the Safe Places ranking design
([`SHELTER_RANKING_ML.md`](SHELTER_RANKING_ML.md)). This is the isolated demo/admin mode: one
compile-time flag turns a demo variant of the app on, and the demo tools themselves live behind
`/demo` in that variant only.

## 1. What it is for

Presenting the app without live services: change the simulated location, put a simulated
disaster advisory on Home, plan "routes" without an openrouteservice key, compare ranking
weights, and drive the hazard overlay — while every simulated surface is labelled so no
screenshot can be mistaken for a live app.

## 2. Isolation rules

- **Compile-time flag.** `lib/core/config/demo.dart`:
  `const bool demoToolsEnabled = bool.fromEnvironment('DEMO_TOOLS')` — default **off**. A
  normal build has no `/demo` route (`router.dart` registers it conditionally), no More tile,
  no Settings entry, and `main()` installs none of the demo overrides.
- **Entry points** (demo builds only): long-press the version row in Settings, or the
  "Demo tools" tile in More.
- **In-memory only.** Nothing about the demo session persists; every launch starts clean.
- **Never distribute a flag build.** `flutter build apk --release --dart-define=DEMO_TOOLS=true`
  contains the panel; that APK is for the demo machine only.

## 3. What the panel can do

| Section | Effect | Honesty marker |
|---|---|---|
| My location | Presets inside/outside QC, any barangay centre via the search sheet, manual lat/lng; applying re-locates so the ranked list, distances and nearest-centre selection react immediately | The demo banner ("Demo overrides active — … simulated") |
| Simulated disaster advisory | flood / earthquake / fire, severity, affected areas, optional message; shows the advisory card on Home and the header bell | `SIMULATED · NOT LIVE` tag on the card + the banner |
| Routes | "Fake routes" switch: straight-line plan, the app's own walking-estimate duration, accessibility reads verified in wheelchair mode, zero network calls | Route attribution says "Simulated direct line — demo tools, not a road route" |
| Ranking weights | Trained v1 (shipped asset) vs hand-set baseline (45/35/20); live diagnostics table per centre (xE/xT/xA, contributions, score) | The Safe Places card keeps its usual provenance line ("Trained weights v1" / "Default weights") |
| Map | Set the hazard overlay group; shows whether the pmtiles protocol registered | — |
| Utilities | Reset all overrides, clear local data, sign out (all confirmed) | — |

## 4. How the seams work

All simulation sits behind providers that already existed:

- `locationServiceProvider` → `DemoLocationService` (returns the override point from
  `current()` and `watch()`, else delegates to Geolocator). Installed in `main()` only when
  the flag is compiled on; tests install the same wrapper over `FakeLocationService`.
- `routeServiceProvider` → `DemoRouteService` (straight-line `RoutePlan` when the switch is
  on, else delegates to the normal Edge-Function/Unavailable service).
- `rankingWeightsProvider` → watches the demo weight mode; `trained` loads the real asset,
  `baseline` returns `RankingDefaults`. `RankingController` is untouched.
- `hazardOverlayProvider` → the panel calls the same `select()` the map sheet uses.

Home renders the advisory card only when `demoAdvisoryProvider` is non-null — which is
compile-time `null` in every normal build. The header bell appears only with a live simulated
advisory; there is no fake alert entry anywhere else.

## 5. Testing

`test/demo_tools_test.dart` covers both worlds: without the flag `/demo` is unreachable and
no tile exists; with the flag (`pumpApp(..., demoTools: true)`) the panel opens, location
presets/clear and the outside-QC state work, the advisory shows/dismisses/revives, fake routes
carry the simulated attribution (the base service is never called), the weights switch flips
the provenance line, and the banner appears exactly while overrides are active.

## 6. Placeholder cleanup that shipped with this

The old placeholder surfaces were removed rather than hidden (2026-10-25):

- The hardcoded sample flood card on Home and the "alerts aren't connected yet" bell — alerts
  now exist only as the clearly-labelled demo advisory.
- The disaster guidebook feature entirely (zero cited sections; an empty "coming soon" screen
  was a placeholder). Routes, More/Prepare entries, the offline-readiness row and Tol's
  guide-content branch are gone; Tol answers guide questions with an official-source pointer.
  The pre-cleanup code is in git history for when reviewed content exists.
- The notification switches (Settings + onboarding) that stored preferences no feature read.
- The offline-readiness placeholder rows for alerts/guidebook/Tol; the screen now lists only
  shipped capabilities.
- Dead l10n (`comingSoon`, `soon*`, `alertDemo*`, all guide/notification keys) and the
  misleading `showSoon` helper name (now `showMessage`).

Kept on purpose: the `DEMO DATA · CENTERS NOT VERIFIED` banner, `NOT REAL DATA` tags and the
sample-centre sentences — the six centres are genuinely unverified sample data, and the app
says so everywhere they appear.
