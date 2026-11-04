# TolongApp — Status and Verification

Last updated: 2026-10-20. How we got here: [`CHANGELOG.md`](CHANGELOG.md).
For setup and the manual QA checklist: [`SETUP.md`](SETUP.md).
For how the code is shaped: [`CODE_GUIDE.md`](CODE_GUIDE.md).

## 1. Where the project stands

| Phase | Scope | Status |
|---|---|---|
| 0 | Audit | Done |
| 1 | Theme tokens, splash, welcome, Supabase auth, onboarding, navigation, profile, logout, guest access, animations | **Done in code.** Sign-up/login still untested end to end; needs a Supabase project |
| 2 | Real readiness score, Supply Coverage, interactive checklist, household editing, Settings, English/Filipino | **Done in code.** Not yet run on a phone |
| 3 | Real QC map, GPS, barangay search, center markers, online routing, navigation screen, offline map, 142 barangays, **NOAH hazard overlay (2026-10-20)** | **Done in code.** Needs `tol-route` deployed, official center data, real-phone testing |
| 4 | Offline readiness center, map downloads, sync queue | **Done in code.** Sync needs the Supabase project. The offline guidebook was **removed 2026-10-25** (no cited content yet — an empty "coming soon" screen was a placeholder); it returns when reviewed material exists |
| 5 | Tol chat, Edge Function, offline fallback | **Done in code.** Needs an AI provider key in Supabase secrets |
| 6 | Hazard layers (**shipped** 2026-10-20), hazard-aware A\* routing (deferred), shelter ranking (**implemented** 2026-10-25) | **Partly done.** Ranking + evaluation: [`design/SHELTER_RANKING_ML.md`](design/SHELTER_RANKING_ML.md) |
| — | Demo/admin tools (**added** 2026-10-25): isolated `DEMO_TOOLS` build with location, advisory, route and weights simulation | **Done.** Internal only, never shipped: [`design/DEMO_TOOLS.md`](design/DEMO_TOOLS.md) |
| 8 | Role-based access control (user / government / admin) and moderated shelter submissions (**added** 2026-10-29) | **Done in code.** Needs a Supabase project to run the two new migrations: [`design/SHELTER_SUBMISSIONS.md`](design/SHELTER_SUBMISSIONS.md) |
| 7 | Full testing, accessibility review, release build | **Automated pass done** (see §2); real-device pass pending |

## 2. How the app is verified

```bash
cd tolong_flutter
flutter test --concurrency=1     # 257 passing; --concurrency=1 is mandatory
flutter analyze                   # clean
```

Parallel test engines exhaust memory on the target (8 GB) machines.

The suite covers:

| File | What it covers |
|---|---|
| `unit_test.dart` | Auth redirects, validation, water/food coverage maths, readiness score, checklist merge, greetings |
| `widget_test.dart` | Welcome without backend, honest login error, guest mode, every tab, Filipino switch |
| `onboarding_test.dart` | Onboarding to dashboard, Filipino chosen during onboarding |
| `phase2_flows_test.dart` | Checklist, custom items, supplies → Home coverage, settings and reduced motion, account deletion |
| `safe_places_test.dart` | Map with demo labels, marker taps, nearest center, outside-QC, location denied/blocked/off |
| `hazard_layer_test.dart` | Hazard grouping, numeric per-band filters, draw-state classification, honest legend wording |
| `hazard_archive_fields_test.dart` | Severity codes pinned to values decoded from the bundled PMTiles archive |
| `qc_area_test.dart` | QC boundary, 142 barangays, barangay search, offline map download/delete |
| `routing_test.dart` | Route drawing, wheelchair profile, route errors, navigation off-route/arrival |
| `phase4_test.dart` | Offline Readiness Center (shipped capabilities only), queued backup |
| `sync_store_test.dart`, `sync_engine_test.dart` | Queue coalescing, tombstones, "newer change wins", retry when server unreachable |
| `tol_test.dart` | Offline intents (EN/FIL), no personal data in AI context, consent, online→offline fallback |
| `ranking_test.dart` | Ranking formulas, trained-weights constraints/monotonicity, shipped asset gates |
| `ranking_parity_test.dart` | Dart ≡ Python feature fixture (1e-9), asset sha pin |
| `evaluation/ranking_evaluation_test.dart` | Golden orderings, τ ablations, explanation audit, benchmarks (prints the §7 tables) |
| `demo_tools_test.dart` | Demo builds: panel reachability both ways, location/advisory/fake-route/weights simulation, banner honesty, flag-off isolation |
| `shelter_submissions_test.dart` | Submission validation (bounds/barangay/capacity/dedupe), center merge, reviewer/admin route gating, submit flow |
| `responsive_test.dart` | Every route at 320×568 and 320×2400 dp, in Filipino with larger text, with no overflow |
| `accessibility_test.dart` | Flutter's tap-target (48 dp), labelled-control and WCAG text-contrast guidelines |
| `error_states_test.dart` | Unreadable center data, failed offline map download |

Backends are replaced with fakes (map, GPS, routing, offline tiles, sync server, Tol, auth), so
these tests prove the app's own logic and UI, not the real services. The port indirection makes
that cheap: `test_helpers.dart` overrides `mapViewBuilderProvider` with `FakeMap`, uses
`MemoryVault` instead of the Keystore, an in-memory `NativeDatabase.memory()`, and a fixed
`clockProvider` (`fixedNow = DateTime(2026,10,18,9,30)`).

### Verified as of 2026-10-25

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **257 passed, 0 failed** (RBAC + shelter submissions included) |
| `python tools/hazard_archive_check/hazard_fields.py --check` | OK: 9 layers match the committed fixture |
| `python tools/psgc_crosscheck/crosscheck.py --check` | OK: 142 barangays match the official PSGC fixture |
| Accessibility guidelines (11 screens) | Pass |
| Small screens and large text (route checks) | Pass |
| Release APK (`flutter build apk --release`) | Built 2026-10-20: **96.9 MB** universal; **34.6 MB** arm64 with `--split-per-abi` (rebuild needed after the 2026-10-25 changes) |
| NOAH hazard overlay in Chrome | Verified 2026-10-20: colours render after a full restart; the "nothing drawn" note stays hidden |

### Not verified / not executed (needs hardware or a backend)

| Area | Why not | How to test |
|---|---|---|
| Real-device pass: GPS, map gestures, TalkBack, low-end-phone performance | No device connected | `SETUP.md` manual checklist, rows 1–71 incl. the hazard overlay (69–71) |
| Hazard archive extraction on Android | Needs a phone; does MapLibre Native accept `pmtiles:///data/…`? | SETUP hazard rows on a real phone |
| Offline map download in airplane mode | Needs device + MapLibre native | SETUP rows for offline maps |
| Sign up / login / password reset / delete account | No Supabase project | Create project, apply 3 migrations, `env.json` |
| Shelter submissions + roles | No Supabase project | Create project, apply the 2 new migrations (`roles`, `shelter_submissions`), seed an admin |
| Backup sync across two phones | No Supabase project | SETUP Phase 4 rows |
| Walking routes (`tol-route`) | Edge Function not deployed, no ORS key | SETUP "Walking routes" |
| Tol online (`tol-chat`) | Edge Function not deployed, no AI key | SETUP "Tol online" |
| 51 MB archive cost acceptance | Decision pending: web fetch-per-page-load, Android first-run copy | Team call after the first phone test |

## 3. Known issues before any public release

- `applicationId` is still `com.example.tolong_flutter`; Google Play rejects `com.example`. Pick
  the real ID (for example `ph.gov.qc.tolong` or the team's domain) before the first upload.
  It can't be changed after publishing.
- Release builds are signed with the **debug key**. Create an upload keystore and a
  `key.properties` (kept out of git) before distributing.
- Evacuation centers are **demo data**, clearly labelled; hazard alerts have no data source. All
  are shown honestly in the app.
- Phase 6 hazard-aware A\* routing was deferred by the team; the ranking part of the
  shelter-ranking spec ([`design/SHELTER_RANKING_ML.md`](design/SHELTER_RANKING_ML.md)) is
  **implemented (2026-10-25)**: ranked safe-places list with trained weights, gap disclosures and
  distance fallback. The modelled-hazard **overlay** ships.

## 4. Known gaps (the one list)

- **No Supabase project provisioned.** Migrations and functions are written and deployable but
  have never run against a live project; everything needing the backend is untested (auth, sync,
  routes, Tol online).
- **`applicationId` is still `com.example.tolong_flutter`** and release builds sign with the
  **debug key** (`android/app/build.gradle.kts:36`, with a TODO).
- **Guidebook is absent, not stubbed** — it was removed on 2026-10-25 because it shipped zero
  cited sections. It returns only with reviewed, sourced content (NDRRMC, QC DRRMO, PAGASA,
  PHIVOLCS, Red Cross); the pre-cleanup code is in git history.
- **Evacuation centres are unverified demo data** (6 records, `verified: false`); real QC DRRMO
  data not yet obtained.
- **Hazard-aware A\*** is deferred and blocked on a QC road graph; **hazard alerts** have no data
  source yet, so nothing is cached for offline use.
- **Shelter ranking is implemented but ranked by expert-labelled policy, not usage data**: the
  pairwise dataset is single-author judgment over synthetic candidates, disclosed in the app
  ([`design/SHELTER_RANKING_ML.md`](design/SHELTER_RANKING_ML.md)). Overlay interactions between
  re-rank and route fetching are limited to the selected centre.
- **`tol-route` deployment is deferred by the team**; routes need a free openrouteservice.org key.
- **iOS is unconfigured.** Android is the only shipped target; maplibre and geolocator
  permissions are declared for Android only. **Sync is disabled on web** (no on-device database).
- **On a new phone, onboarding still runs once** before the first pull restores household data.
- **Reminder notifications do not exist** (the preference-only switches were removed with the
  placeholder cleanup); adding them means `flutter_local_notifications` plus boot-reschedule work.
- **Demo tools are one flag away from shippable** — a release APK built with
  `--dart-define=DEMO_TOOLS=true` contains the admin panel; never distribute that build
  ([`design/DEMO_TOOLS.md`](design/DEMO_TOOLS.md)).
- **Filipino translations** read naturally but should be reviewed by the team before the defense, and
  the **chosen AI model's Filipino answer quality** should be checked with real questions.
- **Rate limiting is per Edge Function instance** (best effort); add a table-based quota if the app
  goes public.
- **Basemap switch** to the bundled PMTiles alternative is one constant away but never verified
  ([`design/MAP_OPTIONS.md`](design/MAP_OPTIONS.md) §4a). The **NOAH reuse licence is
  unconfirmed** — ask UP Resilience Institute before distributing.

## 5. Risks and realistic limits

- **8 GB laptop:** Android builds are slow and can run out of memory. Close other apps; keep the
  Gradle heap at 1.5 GB. Run tests with `flutter test --concurrency=1`; parallel test engines
  exhaust memory.
- **Data availability:** hazard-aware routing and shelter evaluation depend on datasets the team
  does not have yet.
- **Free tiers:** map tiles, routing APIs, Supabase and AI providers all have limits; a demo is
  fine, a public launch is not.
- **Safety wording:** no "safe route" or live-flood claims without validated, current data.

## 6. Decisions for the team

1. **Create the Supabase project** (free tier), run all three migrations, and share the URL and
   publishable key via `env.json`, never via git.
2. ~~Help vs More tab~~: confirmed **More** (2026-10-18).
3. ~~Feature-folder move~~: confirmed and done in Phase 2.
4. Initialise git (`git init`) so every change can be reviewed and reverted. Recommended.
5. Accept or reject the 51 MB hazard archive cost after the first phone test (web: per page
   load; Android: first-run copy).

## 7. Next steps

1. Supabase: project + migrations + `env.json`; deploy `tol-route` (ORS key) and `tol-chat`
   (AI key) when ready. Then seed the first admin (see `SHELTER_SUBMISSIONS.md`).
2. Run the SETUP manual checklist on a real Android phone, including the hazard overlay rows
   (69–71); confirm the archive extraction path works with MapLibre Native.
3. Replace the six demo evacuation centres with QC DRRMO data when available.
4. Choose the final `applicationId` and create a release keystore.
5. Review the Filipino translations as a team.
