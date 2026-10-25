# TolongApp — Change history

What was done and in which order: phase checklists as recorded when each phase ended, plus the
dated test-report updates. Only the hazard-overlay and PSGC work carries explicit dates in the
record; the other phases are ordered but not individually dated.

Currently-open work: [`STATUS.md`](STATUS.md) · How the code is shaped: [`CODE_GUIDE.md`](CODE_GUIDE.md) ·
Setup and the manual QA checklist: [`SETUP.md`](SETUP.md) · Design options: [`design/`](design/).

## 1. Phase 0 — Audit of the starting point

| Area | What was there | Notes |
|---|---|---|
| Toolchain | Flutter 3.47.7 / Dart 3.13.5, Gradle 9.3.1, JDK 25 (Android Studio) | Two earlier Gradle builds crashed with *out of memory*: the daemon asked for `-Xmx8G` on a 7.4 GB laptop. `android/gradle.properties` is now capped at 1.5 GB, 2 workers. |
| Screens | Home, Prepare, Safe Places, matching `Tolong_Screen_Descriptions.pdf` | Visually faithful to the PDF. |
| Data | Everything hardcoded: "Mia", "78%", "2 days", the flood alert, "San Roque Covered Court", "1.2 km · 18 min" | The alert, readiness score and shelter were fabricated sample content shown as if real. |
| Buttons | Save progress, Start navigation, header bell/radio, help icon, "View household readiness", Help tab | All dead or misleading. |
| Architecture | `setState` only, no routing, no persistence, no backend | `lib/views`, `lib/widgets`, flat files. |
| Tests | Flutter's counter template (failed to compile) | |
| Reusable pieces | Theme colours/typography, Logo, Character (SVG mascot with poses), CardBox, IconTile, warning-sound generator | Kept and reused. |

### The plan as written at the start

Recommended architecture:

- **State:** Riverpod 3 (`Notifier` / `AsyncNotifier`, no code generation, which keeps builds light on 8 GB machines).
- **Navigation:** go_router 18 with a `StatefulShellRoute` for the four tabs and a pure `redirectFor()` function for auth/onboarding/guest rules (unit-tested).
- **Layers per feature:** `data/` (repositories), `domain/` (models), `application/` (controllers), `presentation/` (screens).
- **Local-first storage:**
  - Phase 1: `flutter_secure_storage` (Android Keystore-encrypted) for profile, household, contacts; `shared_preferences` for non-sensitive flags.
  - Phase 2+: Drift (SQLite) for inventory, checklists, alerts, evacuation centers and the sync queue. Encrypt sensitive tables or keep them in secure storage.
- **Backend:** Supabase Auth + Postgres with RLS. Secrets that must not ship in the APK (AI provider keys, any service-role key) live only in Supabase Edge Functions.

Integration strategies:

**Maps (Phase 3)**

- **Renderer:** compare `maplibre_gl` (native MapLibre, built-in offline region downloads) and `flutter_map` (pure Dart, simpler, offline through tile caching). Pick after a one-day spike on the target phone.
- **Tiles:** do **not** bulk-download from public openstreetmap.org tile servers. Options to evaluate: a Quezon City **Protomaps PMTiles** extract (single file, can be self-hosted on Supabase Storage and downloaded once for offline use), or a commercial free tier (MapTiler, Stadia). Show OSM attribution on the map.
- **Boundary:** the official QC administrative boundary from a published source (PSA PSGC codes; HDX/OCHA Philippines admin boundaries). Verify licence and accuracy before relying on it; a bounding box is not the boundary.
- **Routing:** the public OSRM demo server is not for production use. Evaluate OpenRouteService or GraphHopper free tiers (walking profile), or self-host OSRM with a QC-only extract. Hazard-aware A* (Phase 6) needs a local road graph plus validated hazard layers.
- **Evacuation centers:** request structured data from QC DRRMO / QC Government. Until then, use a small dataset clearly labelled *development data, not verified*.

**Tol AI assistant (Phase 5)**

- Provider-agnostic interface in the app; one Supabase Edge Function (`tol-chat`) holds the API key and calls the chosen provider.
- Compare Gemini, OpenAI and Claude on current pricing, free tier, Filipino quality, latency and data-use terms. **Check the live terms when deciding; they change often.**
- System prompt and server-side checks forbid inventing hazards, shelters, hotlines or weather; Tol cites data source and freshness for anything dynamic.
- Offline: rule-based FAQ and checklist helper, visibly labelled "Offline guidance".

**Offline (Phase 4)**

- Sync queue table (operation, entity, local id, payload, attempts, last error). Retry on connectivity *hint*, then confirm with a real request.
- Conflict rule: last-writer-wins per record using server `updated_at`, with deleted records tombstoned so they can't reappear.
- Bundle the DM Sans and Fraunces fonts as assets (they currently download on first launch through google_fonts).

## 2. Phase 1 — Theme, auth, onboarding, navigation

Completed:

- [x] Central theme tokens: colours (primary, secondary, background, surface, success, warning, error), spacing, radii, icon sizes, durations, button/input/dialog/sheet themes (`lib/theme.dart`)
- [x] Reduced motion: honours the Android setting and an in-app switch (More → Reduce motion); all custom animations collapse to zero duration
- [x] Animated splash, welcome screen with mascot, card entrance animations, button press feedback, animated progress bars, bottom-nav transition
- [x] Supabase email/password auth: register (name, email, password + confirm, age, barangay, privacy consent), login, forgot password, reset via email link, logout, encrypted session storage
- [x] Honest behaviour without Supabase config: banner on Welcome; auth actions fail with a clear message
- [x] 5-step onboarding (about you, household, contacts, preferences, welcome) with skip for optional questions; completion stored per account
- [x] Profile & household screen: view and edit profile and household, add/edit/remove contacts with confirmation
- [x] Emergency access (guest mode): separate local data slot, persistent banner, remembered across launches
- [x] Navigation: Home / Prepare / Safe places / More, profile from the avatar, real greeting by time of day, real date
- [x] Every placeholder labelled (SAMPLE DATA, DEMO · NOT LIVE, PREVIEW, NOT REAL DATA); unfinished buttons explain themselves instead of doing nothing
- [x] Supabase migration for `profiles` with RLS (`supabase/migrations/`)
- [x] Android: INTERNET permission, deep link for auth emails, app label "TolongApp"
- [x] Automated tests (unit + widget), run at a 360 dp phone width

## 3. Phase 2 — Real data: readiness, supplies, checklist, settings

Completed:

- [x] Feature-folder structure: `lib/core`, `lib/shared/widgets`, `lib/l10n`, `lib/features/<feature>/{domain,data,application,presentation}`
- [x] **English / Filipino** with `flutter_localizations` + ARB files (`lib/l10n/app_en.arb`, `app_fil.arb`, ~370 strings). No hardcoded UI strings remain. Language follows the device on first launch, can be switched on Welcome, in onboarding, in Profile and in Settings, and is saved and synced to the profile.
- [x] **Supply Coverage** (`features/supplies`): add/edit/delete items, 7 categories, 11 units, expiry dates, optional daily use, per-unit amounts. Water coverage in liters (L, mL, US gallon, or liters per bottle) and food in meals are calculated separately and never added together. Expired items are excluded and flagged; items expiring within 30 days are warned about. Items with unknown per-unit amounts are left out and counted, never guessed. Shortfalls are shown against a configurable target.
- [x] **Interactive go-bag checklist** (`features/prepare`): 19 standard items in 8 categories, plus 7 household-specific suggestions shown only for children, seniors, pets or assistance needs. Check/uncheck auto-saves; custom items can be added, edited and removed (with confirmation); template items can be renamed; reset keeps custom items and edits. Saved state is keyed by stable template ids, so template updates never overwrite user edits.
- [x] **Household readiness** (`features/readiness`): weighted score shown on Home and in a details screen with per-area points, completed and missing items, the formula, and next actions.
- [x] **Preparedness Knowledge Agent** (rule-based, `readiness/domain/recommendations.dart`): ordered recommendations from saved data only (expired items, then water and food shortfalls, contacts, household, unpacked checklist items, missing supply categories, expiring items). Each one links to the screen that fixes it.
- [x] **Settings**: language, reduce motion, text size, preparedness targets, notification preferences, location preference, privacy notice, data-storage explanation, clear data on this phone, change password (reset email), delete account, about, version, data sources, map attribution, disclaimer. Every control persists.
- [x] Account deletion through a `security definer` RPC (`supabase/migrations/20261019000000_delete_own_account.sql`), so no service-role key ships in the app.
- [x] Home now shows real data: computed score and ring, water coverage line, items left to pack, household size. The fabricated "78%", "2 days", "San Roque Covered Court" and "1.2 km · 18 min" are gone; the alert and map remain clearly labelled demos.
- [x] 35 automated tests: formulas (including the 4 people / 24 L / 8 L per day = 3 days example), unit conversions, expiry, checklist merging, readiness weights, recommendation order, both languages, and end-to-end flows (onboarding, checking items, adding supplies, settings, Filipino switch, account deletion).

### Formulas (for the defense)

- **Water days** = usable liters ÷ (household size × liters per person per day). Default 3.8 L (≈1 US gallon, the widely used guideline).
- **Food days** = usable meals ÷ (household size × meals per person per day). Default 3.
- **Supply score** = 0.30 × min(1, water days ÷ target) + 0.30 × min(1, food days ÷ target) + 0.10 for each of medicines, first aid, hygiene and lighting with at least one unexpired item. Default target is 3 days.
- **Readiness** = 40 × checklist completion + 30 × supply score + 15 × min(1, contacts ÷ 2) + 15 × (0.5 if household saved + 0.5 if barangay set).

### Design decision: local storage

Phase 2 stores supplies and checklist progress as JSON documents in encrypted storage (Android Keystore), behind repository classes, the same way as the household data. SQLite (Drift) moves to Phase 4, together with the sync queue, where relational queries and migrations are actually needed. Swapping the storage only touches the `data/` folders.

### Not done / limitations (as recorded at phase end)

- [ ] Sign-up, login, email verification, password reset and account deletion not yet run against a real Supabase project
- [ ] Household, contacts, supplies and checklist are local-only (encrypted on device); cloud sync comes with the sync queue (Phase 4)
- [ ] Onboarding completion is stored on the device, so logging in on a second phone repeats onboarding (prefilled)
- [ ] Barangay is free text; replace with the official list of 142 QC barangays from PSA PSGC *(closed by the Phase 3 PSGC cross-check)*
- [ ] Notification switches store preferences only; reminders need `flutter_local_notifications` (planned with alerts)
- [ ] Filipino translations were written for natural everyday Filipino, but should be reviewed by the team before the defense
- [ ] Disaster Guidebook and Offline Readiness still show "Coming soon" (Phase 4)
- [ ] Fonts download at first launch (bundle them in Phase 4) *(closed in Phase 7)*
- [ ] App ID is still `com.example.tolong_flutter`; choose the final ID before any release build

## 4. Phase 3 — The real map: QC, barangays, routing, the hazard overlay

Completed:

- [x] Live map: MapLibre (`maplibre_gl` 0.27.1) with OpenFreeMap Positron tiles, framed on Quezon City, pan limited to Metro Manila, zoom 10–18, attribution shown. Verified rendering in Chrome (release web build).
- [x] Controls: zoom in, zoom out, show my location, show all of QC. Camera moves are animated, or instant under reduced motion.
- [x] Location (`geolocator` 14): asked only when the user taps "Show my location" or asks for a route; handles denied, permanently denied (opens app settings), location off (opens location settings), failure, and users outside the approximate QC area.
- [x] Evacuation centers: structured model (id, name, barangay, address, lat/lng, type, accessibility, capacity, facilities, status, source, last verified, verified flag). A 6-point development dataset is labelled DEMO / NOT REAL DATA everywhere, with every unverified field shown as "Not verified".
- [x] Markers, detail card, accessible list sorted by straight-line distance, nearest center auto-selected when the user is inside QC. Map taps near a marker select it (fallback for platforms where annotation taps don't fire, seen on web).
- [x] Stage A routing: `supabase/functions/tol-route` Edge Function proxies OpenRouteService `foot-walking` / `wheelchair`, keeps the API key server-side, validates coordinates to Metro Manila, burst-limits per IP, and maps errors to codes. The app draws the route line and shows distance, ORS walking time, a disclaimer (no live flood/closure knowledge) and ORS attribution. Without Supabase it says routing isn't set up.
- [x] Navigation screen: route preview with live location (10 m updates), remaining straight-line distance, off-route warning (> 60 m from the line), arrival (< 40 m), end navigation. Labelled "not turn-by-turn".
- [x] 54 automated tests, including routing, error states and the navigation flow with a fake location stream.

- [x] **Quezon City boundary**: OSM relation 106569 (ODbL), 140 ways assembled into one closed ring, simplified 849 → 306 points (~11 m), bundled in `assets/data/qc_boundary.json`. Ray-casting point-in-polygon now decides "inside / outside QC" (the approximate rectangle is only a fallback). Drawn as an outline on the map; "Show all of QC" frames it. It is community-mapped, not a legal survey; the app says so in attribution.
- [x] **142 barangays**: OSM admin_level=10 inside QC, every one with a PSGC code, count matches PSA's 142, no duplicates. Bundled in `assets/data/qc_barangays.json` with approximate centers. Search ignores case, accents, punctuation and "Sto./Sta." abbreviations.
- [x] **Barangay search on the map**: search bar → list → map flies to the barangay and centers are sorted by distance from it (labelled as such).
- [x] **Barangay picker in forms**: sign-up, onboarding and profile now only accept names from the official list (type-ahead suggestions), and store the canonical spelling ("santo nino" → "Santo Niño").
- [x] **Offline Quezon City map**: MapLibre offline region for the QC boundary's bounding box, zoom 10–14 (vector tiles overzoom beyond). The estimate is checked in tests to stay below OpenFreeMap's 3,000-tile limit; 4 parallel requests max; distinct TolongApp User-Agent. Progress, done (date and size), retry and delete-with-confirmation. Reachable from Safe places and Settings → Offline maps. Web shows "Android only".
- [x] 65 automated tests.

- [x] **NOAH hazard overlay** (2026-10-20): four modelled-hazard groups (flood depth, landslide, storm surge, debris flow) from Project NOAH, clipped to Quezon City and bundled in `datasets/` (77 MB, committed on purpose). One fill layer per severity band, each with its own severity filter (`hazardFilterExpression()`), so bands shade distinctly instead of stacking; source registration is idempotent, because group switches never stack duplicate sources (web's `addSource` throws on a repeat — regression-tested). The legend frames colours as modelled exposure, not a safety guarantee, and names what NOAH does not model (earthquakes, fire); storm surge honestly reports no data for inland QC; a failed PMTiles registration disables all groups with an explanation (`hazard_protocol*.dart`). Same day, after a Chrome check showed legend but no colours: the dev server does not honour HTTP byte ranges, so pmtiles' `FetchSource` was replaced by a whole-file source on web (`web/vendor/hazard_archive.js`), and Android/iOS now extract the archive to a seekable file in the app-support directory on first run (`hazard_archive.dart`) — MapLibre Native cannot open a bundled asset through `pmtiles://` at all. A second Chrome check then showed the *same* symptom with **no error at all**, and decoding the archive settled the real cause: `Var`/`HAZ` are stored as **numbers** while the filter compared them as strings, and in MapLibre `1 == '1'` matches nothing — the legend rendered, the map stayed blank, nothing threw. The filter is numeric now; the observed value set per layer is pinned to decoded-tile data (`tools/hazard_archive_check/hazard_fields.py --check` + `test/fixtures/hazard_archive_fields.json`); and the map reports "features loaded but no filter match" as a legend note instead of failing silently (`classifyDraw` → `hazardNothingDrawn`). 36 tests in `hazard_layer_test.dart`, 13 more in `hazard_archive_fields_test.dart`. Confirmed drawing in Chrome on 2026-10-20 from a full restart (colours render; the no-match note stays hidden); the Android/phone side is in the pending device checklist. Details and licence question: [`design/MAP_OPTIONS.md`](design/MAP_OPTIONS.md) §4a.

- [x] **PSGC cross-check** (2026-10-20): all 142 barangay names and codes now match the PSA Philippine Standard Geographic Code masterlist (Third Quarter 2026 release, 2026-10-12). Fixed 5 entries that still carried old 9-digit correspondence codes (`1374040xx` → `13813000xx`) and adopted PSA's official spellings for 9 names (e.g. "Aurora", "Teachers Village East", "E. Rodriguez"). psa.gov.ph refuses automated downloads, so the masterlist came from a mirror, validated against a second independent mirror and against psa.gov.ph's rendered tables; provenance is recorded in `test/fixtures/psgc_qc_official.json` and guarded by `tools/psgc_crosscheck/crosscheck.py --check` plus a test.

### Remaining in Phase 3

- [ ] Deploy `tol-route` and set `ORS_API_KEY` (needs the Supabase project and a free openrouteservice.org key)
- [ ] Replace demo centers with QC DRRMO data
- [ ] Test on a real Android phone: GPS, map gestures inside the scrolling page, the offline download in airplane mode, performance; the SETUP manual checklist rows (30–47) are being run manually by the team

## 5. Phase 4 — Offline-first readiness, sync, guidebook

Completed:

- [x] **Disaster guidebook structure**: Flood, Earthquake, Fire, Typhoon, First aid. Content lives in `assets/guidebook/guidebook.json` (bundled, so offline) with English/Filipino text, phases (before/during/after), steps with optional bundled images, links to go-bag items, and a required `source` per section. **Sections without a source are dropped by the parser.** No guide content was invented; every category shows a "coming soon" state. Opens from Prepare, More and the Readiness Center.
- [x] **Offline Readiness Center** (header signal icon, More → Offline readiness): one honest list of street map, QC boundary/barangays, evacuation centers (flagged as unverified sample), hazard alerts (none connected), guidebook (0 of 5 with content), household data (encrypted on device), Tol offline (not yet), and account backup status, plus offline map storage and "Back up now".
- [x] **Drift database** (`lib/core/database/app_database.dart`): `sync_queue`, `record_versions`, `sync_states`. Dates stored as ISO-8601 text to keep milliseconds and UTC (see `build.yaml`). Regenerate with `dart run build_runner build`.
- [x] **Sync queue + engine** (`lib/features/sync/`): every write by a signed-in user records `(entity, record id, deleted, modified time)`; repeated edits coalesce, so there are no duplicates. A pass pushes due entries (contents read from the encrypted vault at push time), then pulls server changes since the last cursor. Triggers: 2 s after a change, on reconnect (connectivity is treated as a hint only), at sign-in, and "Back up now". Failures keep entries queued with backoff of 30 s, doubling up to 1 h.
- [x] **Conflict rule ("newer change wins")**, identical on server (`sync_push` only overwrites when the incoming `client_modified_at` is the same or later) and device (`shouldApplyRemote`: a pulled record replaces the local one only if it is newer than both the local copy and any unpushed local change; ties keep the local copy). Deletions are tombstones so other devices learn about them. A queue entry is only removed if it wasn't edited again during the push, so no edit is silently lost.
- [x] **Supabase** `supabase/migrations/20261020000000_sync_records.sql`: one `sync_records` table (user, entity, record id, JSON data, tombstone flag, client and server timestamps), RLS select/insert/update own rows only, no delete policy, 32 KB per record, `sync_push` batch function (security invoker, at most 500 records). Rows cascade-delete with the account.
- [x] Privacy notice, Settings storage text and "clear data" text updated to describe the backup honestly. Guests never sync.
- [x] 83 automated tests, including an in-memory Drift store, a fake server applying the same SQL rule, and an end-to-end widget test (check an item → queued → uploaded → "Everything is backed up").

### Design decision: what Drift holds

The queue stores only *which* record changed, never its contents, so no personal data sits in the unencrypted SQLite file. The encrypted vault (Android Keystore) stays the source of truth. Moving the records themselves into SQLite would need SQLCipher; that isn't needed for the current data volume and can be added later behind the same repositories.

### Not done / limitations (as recorded at phase end)

- [ ] Not run against a real Supabase project yet (migration 3 must be applied)
- [ ] On a new phone, onboarding still runs once before the first pull restores household data
- [ ] Sync is disabled on web (the web preview has no on-device database)
- [ ] Guidebook content must be written from cited official sources (NDRRMC, QC DRRMO, PAGASA, PHIVOLCS, Red Cross) and reviewed
- [ ] Hazard alerts have no data source yet, so nothing is cached for offline use

## 6. Phase 5 — Tol, the preparedness agent

Completed:

- [x] Provider comparison with sources and a recommendation ([`design/TOL_AI_OPTIONS.md`](design/TOL_AI_OPTIONS.md)): Claude Haiku 5.5 for production (≈$0.0003 per reply, API data not trained on by default), Gemini Flash-Lite free tier for zero-cost development with household context off.
- [x] **`tol-chat` Edge Function** (`supabase/functions/tol-chat`): provider adapters for Anthropic, Gemini and OpenAI chosen by `TOL_PROVIDER`/`TOL_MODEL` secrets; API key never in the app; JWT required (signed-in users only); per-user burst limit; input limits (12 messages, 1,000 chars each, 6,000 total); 25 s timeout; clear error codes.
- [x] **Safety**: system prompt forbids inventing hazards, rescues, shelter availability, weather, routes-as-safe and phone numbers; tells the model what the app really has (no live alerts, unverified centers, no guidebook content yet); emergencies → 911 and officials first. **Output guard** removes any 7+ digit number from replies (911 survives). Every online reply is labelled "AI-generated · may be wrong · not an official advisory".
- [x] **Consent**: household summary (size, children/seniors/pets yes/no, whether there are assistance needs, barangay, readiness, missing supply categories) is sent only when the user turns it on (chat menu or Settings → Privacy). Names, ages, phone numbers, contacts and medicine names are never sent (tested). `TOL_SHARE_CONTEXT=false` can force it off server-side.
- [x] **Offline Tol** (`features/tol/domain/offline_guide.dart`): keyword intents in English and Filipino, checked in safety order (emergency, then "is something happening now" → PAGASA/QC DRRMO, then hazard guides, go-bag, water, food, expiry, readiness, evacuation, contacts, greeting). Answers come only from saved data (checklist, supply coverage, readiness, contacts, guidebook status) and are labelled "Offline guidance". It is explicitly not a language model.
- [x] Online → offline fallback with "Try online again"; guests and unconfigured builds use offline mode with an explanation.
- [x] **Chat UI**: floating Tol button (gentle bob, stops under reduced motion, hidden on Safe places so it never covers map controls), chat screen with bubbles, typing indicator, suggested questions, online/offline status, clear conversation with confirmation. History kept encrypted on device (last 60 messages).
- [x] Fixed a reduced-motion bug found while testing: onboarding "Next" now jumps instead of animating with a zero duration.
- [x] 93 automated tests.

### Not done / limitations (as recorded at phase end)

- [ ] Needs `supabase functions deploy tol-chat` plus a provider key
- [ ] Filipino answer quality of the chosen model should be checked by the team with real questions
- [ ] Rate limiting is per Edge Function instance (best effort); add a table-based quota if the app goes public

## 7. Phase 6 — Hazard-aware routing deferred; shelter ranking specified

Hazard-aware routing (A* over a QC road graph with flood/hazard layers) was deferred by the team
on 2026-10-18, together with the Supabase setup. Walking routes still use OpenRouteService via
`tol-route` once it is deployed, with the "not a safety guarantee" wording.

The shelter-ranking part of Phase 6 resumed on 2026-10-19: the hazard-band filter fix is
implemented in the map overlay (2026-10-20), while the hazard exposure query layer, the
scoring engine and the trained ranking weights are specified in
[`design/SHELTER_RANKING_ML.md`](design/SHELTER_RANKING_ML.md). The A\* plan itself is unchanged in
[`design/MAP_OPTIONS.md`](design/MAP_OPTIONS.md) §4b.

## 8. Phase 7 — Testing, accessibility, release build

### Test report — 2026-10-18 baseline

Date: 2026-10-18 · App version 0.5.0+5 · Flutter 3.47.7 / Dart 3.13.5 · Windows 10, 8 GB RAM

Supabase setup and Phase 6 (hazard-aware routing) were skipped at the team's request, so anything
that needs a backend is listed as "Not executed".

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **145 passed, 0 failed** |
| Accessibility guidelines (12 screens) | Pass after fixes (below) |
| Small screens and large text (37 route checks) | Pass after fixes (below) |
| Release APK (`flutter build apk --release`) | Built, **96.9 MB** universal APK (all CPU types). With `--split-per-abi`: **34.6 MB** (arm64, most phones), 29.7 MB (older 32-bit) |
| Real Android device | **Not tested** |
| Supabase auth, backup sync, Edge Functions (routes, Tol online) | **Not tested**: no project yet |

Accessibility fixes made in Phase 7:

- **Tap targets** raised to 48 dp: header icons, profile avatar (visible circle unchanged), Tol button, welcome EN/FIL switch, barangay search bar, flood-alert sound toggle.
- **Text contrast** raised to at least 4.5:1: muted text, eyebrow labels, dates, footers, nav labels, warning/success/error text, info and success messages, guest banner. The primary sage was deepened slightly (#63896D → #52775D) so white text on buttons passes. Decorative tints and chevrons are unchanged.
- The flood-alert `AudioPlayer` is now created on first tap instead of on screen load.

Responsiveness fixes (earlier in Phase 7):

Fixed overflows found at 320 dp width and large text: profile section headers, supplies essentials grid (now wraps and grows), readiness area points, Tol mode chip, supply expiry field, and all bottom sheets (now scroll). Fonts are bundled (DM Sans, Fraunces, OFL) so text renders the same offline; the app no longer downloads fonts.

Build notes:

- The first release build failed: Android lint ran out of Metaspace on the `audioplayers` plugin. Fixed by raising `-XX:MaxMetaspaceSize` from 512m to 1024m in `android/gradle.properties` (heap stays at 1.5 GB for the 8 GB laptop). Second build: 5.5 minutes.
- The APK is large because MapLibre ships native libraries for each CPU type. For sharing a test build, use `flutter build apk --release --split-per-abi` and install `app-arm64-v8a-release.apk`; for Play, upload `flutter build appbundle`.
- Material icons are tree-shaken (1.6 MB → 15 KB).

Start-up fix (after the report):

- Removed a fixed 1.4 s wait on the splash screen; the session is ready as soon as saved settings are read.
- The Android launch screen (shown until Flutter draws its first frame) is now the app's cream background instead of white, including the Android 12+ system splash.
- The app icon is still Flutter's default logo, so it isn't shown on the launch screen. A real TolongApp icon is needed.
- Debug builds (`flutter run`) still start slowly on a phone; that's normal for debug mode. Use the release APK to judge start-up time.

Also completed in Phase 7: error-state tests for unreadable bundled data; the flood-alert audio player made lazy; fonts bundled as assets with `google_fonts` removed.

### Update 2026-10-20 — hazard tests and the PSGC cross-check

What changed in the suite:

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **174 passed, 0 failed** (was 145) |

New since the 2026-10-18 report:

- `hazard_layer_test.dart` (28 tests): bundled PMTiles archives exist and are real, hazard grouping and layer specs are unique per severity band, every band layer filters on its own severity code (`Var` for flood, `HAZ` for the rest — regression tests for a bug where bands rendered without filters), legend wording never claims safety, the picker degrades honestly when the PMTiles protocol fails to register.
- `qc_area_test.dart` gains a fixture test: barangay names and codes must match `test/fixtures/psgc_qc_official.json` exactly — the PSA PSGC masterlist (Third Quarter 2026 release, 2026-10-12) with provenance, since psa.gov.ph refuses automated downloads and the datafile was taken from a validated mirror.
- `tools/psgc_crosscheck/crosscheck.py`: same check outside Dart (`--check`), plus `--extract` to rebuild the fixture from a fresh mirror datafile.

Data corrections while cross-checking: 5 barangays carried old 9-digit correspondence codes (now `13813000xx`), and 9 names were aligned to PSA's official spellings.

What was **not** re-verified on hardware:

- The debug APK was rebuilt (`flutter build apk --debug`) but the emulator pass was abandoned — the emulator would not reach a stable boot on the 8 GB laptop this session. The SETUP manual checklist (rows 30–47 and the hazard-overlay rows 69–71) was handed to the team to run on a real phone; results are appended to [`STATUS.md`](STATUS.md).
- Everything needing a backend (routes, Tol online, sync) is still untested — no Supabase project yet.

### Update 2026-10-20 — hazard overlay transport fix

A manual Chrome check (`flutter run -d chrome`) found the hazard picker and legend working but no colours on the map, with no 404. Diagnosis: protocol registration, the map source and the band layers were all fine — pmtiles' HTTP `FetchSource` requires the server to honour **byte ranges**, and Flutter's dev server (like any plain static server) answers a `Range` request with a 200 and the whole 51 MB, which the library rejects. A documented claim that "Flutter's dev server handles it" was wrong.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **176 passed, 0 failed** (was 174) |

Changes:

- Web loads the archive as a **whole file** into a `File`-backed pmtiles `FileSource` (`web/vendor/hazard_archive.js` glue + a rewritten `hazard_protocol_web.dart`) — no byte-serving dependency, so the overlay works in `flutter run -d chrome` and on any static host. Cost: one 51 MB fetch per page load, on first overlay use.
- Android/iOS extract the bundled archive once into the app-support directory (atomic `.part` + rename, `hazard_archive.dart`); the map reads `pmtiles://<extracted path>`, because MapLibre Native cannot open a bundled asset through `pmtiles://` at all (deflated APK entry, no filesystem path).
- The registered key is now derived from one constant (`hazardArchiveKey` in `map_style.dart`), fixing a latent mismatch where `main()` registered the *prefixed* URL; `hazard_layer_test.dart` asserts the key equals the source URL minus the scheme and dropped a `build/web` check that passed vacuously.

What is **not** verified yet (manual checks pending): the Android extraction on a real phone (including whether MapLibre Native accepts the `pmtiles:///data/…` path form) and the 51 MB cost acceptance (web fetch-per-page-load, Android first-run copy). The Chrome colours from this fix verified the same day with the next update.

### Update 2026-10-20 — the real cause: filter compared a string to a number

A second Chrome check still showed legend with no colours and — crucially — **no error**. That ruled the transport out and pointed at a silent filter problem. Decoding the bundled archive directly (tile z14/13697/7520, then every tile) settled it: `Var`/`HAZ` are stored as **numbers** (`INT 1..3/1..4`), while the style filter compared them against the **string** codes `'1'…'4'`. MapLibre's `==` compares types strictly, so `1 == '1'` is false for every feature: zero matches, no fills, no exception. The legend rendered as before, because it is driven by `band.level`, not by what the map drew. The earlier "transport fix" was still a real defect (the dev server legitimately cannot byte-serve) but was not what the user saw.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **195 passed, 0 failed** (was 176) |
| `python tools/hazard_archive_check/hazard_fields.py --check` | OK: 9 layers match the committed fixture |

Changes:

- `HazardSeverityBand.code` is now an `int`, and the filter emits `['==', ['get','Var'], 1]` — numeric, matching the archive. Layer ids are unchanged.
- **The data backs the ranges.** `tools/hazard_archive_check/hazard_fields.py` decodes **all 169 tiles** (stdlib-only, reuses the proven PMTiles directory/MVT decoding) and writes `test/fixtures/hazard_archive_fields.json` — per layer: attribute, storage type, observed values (`flood*` Var {1,2,3}; `landslide` HAZ {1,2,3,4}; surge {1,2,3}; `debris_flow` {3,4}; archive sha256/size/tiles as provenance). `--check` re-decodes and diffs. New `hazard_archive_fields_test.dart` (13 tests) asserts every group's attribute is present and numeric in all of its source layers and that **every observed value has a declared band**. The reverse (a declared band with no data) is allowed on purpose: the legend shows the full scale for groups whose QC extract uses only part of it.
- **Silent failures are visible now.** `hazard_layer_service.dart` gained a pure `classifyDraw` + `HazardDrawState`; `map_view.dart` hooks `onMapIdle`: with an active group it queries the source unfiltered and again under a new whole-group filter (`hazardGroupFilterExpression`; `['in', ['get', attr], [codes]]`), classifying `drawn`, `viewHasNoData` (stays quiet: normal for empty tiles) or `filterMatchedNothing`. That last state — data loaded, filter matched none — reaches the legend as a short note (`hazardNothingDrawn`, both languages, generated); it is worded as an app-problem report, never as evidence the hazard is absent. The comparison cannot happen on a colourless run again without the legend saying so.
- `HazardLayerSpec` group-filter and draw-state helpers are unit-tested in `hazard_layer_test.dart` (+6 tests, now 36), including a regression test asserting the filter code is an `int`.

What is **not** verified yet (manual checks pending): Android extraction on a real phone (including whether MapLibre Native accepts the `pmtiles:///data/…` path form) and 51 MB cost acceptance. Chrome colours **verified 2026-10-20**: a full `flutter run -d chrome` restart loaded the new `web/vendor/hazard_archive.js` script tag (it does not load on a hot-reload of an already-open page) and the hazard colours now render, with the `hazardNothingDrawn` note correctly staying hidden.

### Update 2026-10-25 — shelter ranking v1: pair data, trained weights, evaluation

Phase 6's shelter-ranking track was implemented end to end per
[`design/SHELTER_RANKING_ML.md`](design/SHELTER_RANKING_ML.md) (three factors: modelled exposure
at the candidate's own point, straight-line travel estimate, wheelchair accessibility, all
capped/neutralized exactly as specified; the PHIVOLCS catalogue stays context only — every site
has nearby events in 2016-2022, which says more about recording networks than about hazard, so it
never became a weight).

Changes:

- **Dart engine + asset loading.** `features/safe_places/domain/ranking.dart` holds the formulas
  (score, pairwise probability, contributions, constraint check, walking-mode renormalization,
  and the exposure formula home `exposureFromBands`); `data/hazard_bands_repository.dart` loads
  the 82 KB `hazard_bands.json` (148 sites, flood/landslide/debris bands + exposure sampled from
  `qc_flood.pmtiles`) inside a compute isolate with graceful null fallback;
  `data/ranking_weights_repository.dart` loads `ranking_weights.json` and falls
  back to the hand-set 45/35/20 on any problem — never a crash, never a partial model.
- **Safe Places integration.** With a location or barangay set on file, the centres list orders
  by modelled score (distance tiebreak), each card discloses weights provenance (default vs
  trained v1), modelled exposure, travel (estimated vs route) and the accessibility reading;
  without hazard data the list honestly falls back to distance. All new strings exist in both
  languages.
- **Utility pipeline (tools/ranking, all stdlib or the three listed deps).** `extract_bands.py`
  rebuilds the hazard asset from the NOAH archive (`--extract`/`--check`); `seismic_context.py`
  joins the PHIVOLCS catalogue 2016-2022 (context only, drift-guarded); `make_pairs.py` authors
  the dataset as 119 explicit `decidingFactor`-tagged preference rules with per-pair rationales
  (coverage gates: >= 25 pairs per factor, every flood band, every travel bucket); `check_parity.py`
  writes the Dart<->Python feature parity fixture (`exposure_parity.json`, 1e-9 tolerance,
  synthetic absence rows included); `train.py` fits Bradley-Terry logistic weights with SLSQP
  (sums to exactly 100, exposure floored at 30, 4-decimal rounding with exact-sum repair,
  lambda by 5-fold out-of-fold log loss, byte-deterministic re-runs) and ships
  `assets/data/ranking_weights.json` (30.0 / 58.1894 / 11.8106 with the training metrics in the
  file). The trained fit **ties** the hand-set baseline's CV accuracy (0.9250), so the shipped
  file keeps full provenance about the tie — documented rather than hidden.
- **Evaluation (test/evaluation/ranking_evaluation_test.dart + test/fixtures/ranking_golden.json).**
  12 golden candidate sets pin orderings under both weight sets; ablation tables (Kendall's τ)
  over the 148-site universe; monotonicity violations 0/200 per ablation for any non-negative
  weights; explanation audit (zero-weight factors never appear as reasons; contributions sum to
  score); forbidden-claims scan over 36 ranking strings in EN/FIL (0 hits); benchmarks
  (cold parse in an isolate: ~14 ms; `exposureAt` x 10 000: ~93 ms; full ranking N=6: ~175 µs,
  N=1000: ~1.4 ms; asset 82 KB vs the 5 MB gate; ORS budget: the engine re-rank uses straight-line
  estimates, 0 calls — a real route request happens only for the selected centre, <= the spec's 3).
- Parity: `test/ranking_parity_test.dart` recomputes every fixture row with the Dart formula and
  pins the fixture's sha to the shipped asset.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **243 passed, 0 failed** (ranking phases 0–2 had brought the suite to 228 before this update) |
| `python tools/ranking/check_parity.py` | OK (22 asset rows + 3 synthetic edge rows) |
| `python tools/ranking/train.py` | Deterministic re-run reproduces the shipped file byte-for-byte |

Known limits (already in spec §10): single-author expert labels over synthetic candidates; the
1.2 m/s travel estimate underestimates crowded or wheelchair-slow walks; no outcome data exists
anywhere to validate against.

### Update 2026-10-25 — demo/admin tools + placeholder cleanup

Two related changes: an isolated demo mode for presentations, and the removal of every
placeholder surface now that simulation has a proper home.

**Demo tools** ([`design/DEMO_TOOLS.md`](design/DEMO_TOOLS.md)): a compile-time
`--dart-define=DEMO_TOOLS=true` build gets a hidden `/demo` panel (Settings version-row
long-press, or a More tile in that build only) that can simulate the app's inputs:

- **Location** — QC presets, one outside-QC preset, any barangay centre, manual coordinates;
  applying re-locates immediately, so the ranked list and distances react.
- **Simulated disaster advisory** — flood/earthquake/fire with severity, area and message,
  shown on Home with a `SIMULATED · NOT LIVE` tag; the header bell opens it (and exists only
  while an advisory is live).
- **Fake routes** — straight-line plans with the app's own walking-estimate duration and a
  simulated attribution, so `By route` travel and the wheelchair-verified state demo without
  an ORS key (zero network calls).
- **Ranking weights** — trained v1 vs hand-set baseline, plus a per-centre diagnostics table
  (xE/xT/xA, contributions, score).
- **Map + utilities** — hazard overlay selection, reset overrides, clear local data, sign out.

Isolation: the flag defaults off, the route/entries/overrides don't exist in normal builds,
the demo session is in-memory only, and a thin "Demo overrides active" banner shows while any
override is live. Normal builds keep the plain providers; tests install the same wrappers over
fakes via `pumpApp(..., demoTools: true)`.

**Placeholder cleanup** — removed rather than hidden:

- The hardcoded sample flood card on Home and the dead alerts bell (alerts are demo-only now).
- The **disaster guidebook feature entirely** — it shipped zero cited sections, so every
  "coming soon" surface (routes, More/Prepare entries, offline-readiness row, Tol's guide
  branch, the asset, its tests and l10n) is gone; Tol answers guide questions with an
  official-source pointer. Pre-cleanup code is in git history for when reviewed content exists.
- The **notification preference switches** (Settings + onboarding) that no feature ever read,
  and the offline-readiness placeholder rows; that screen now lists only shipped capabilities
  (map, area data, centres, household, backup).
- Copy that promised the future: "will replace them", "once connected", "isn't set up yet",
  "won't work yet" — reworded as present-tense facts; dead l10n keys deleted; `showSoon`
  renamed to `showMessage` (every call site is a confirmation, not a promise).

Kept on purpose: the sample-centre honesty labels (`DEMO DATA`, `NOT REAL DATA`, sample notes,
attribution) — the six centres are genuinely unverified, and the app says so everywhere.

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| Automated tests (`flutter test --concurrency=1`) | **245 passed, 0 failed** (was 243) |
| Demo isolation | Without the flag: no `/demo` route, no tile, no panel (tested) |

## 9. Decision log (as recorded 2026-10-18)

1. Create the Supabase project (free tier), run the migrations, and share the URL and publishable key via `env.json`, never via git. *(Still open — now counts three migrations.)*
2. ~~Help vs More tab~~: confirmed **More** (2026-10-18).
3. ~~Feature-folder move~~: confirmed and done in Phase 2.
4. Initialise git (`git init`) so every change can be reviewed and reverted. Done — the repo is now git-managed.
5. Phase 3 needs a decision on the map tile source and routing service *(superseded: PMTiles chosen for the hazard overlay — see §4 — and `tol-route` deployment deferred by the team)*.
