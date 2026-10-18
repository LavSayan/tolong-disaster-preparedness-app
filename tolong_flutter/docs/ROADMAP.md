# TolongApp — Audit, Plan and Status

Last updated: 2026-10-18 (end of Phase 2)

## 1. Audit of the starting point (Phase 0)

| Area | What was there | Notes |
|---|---|---|
| Toolchain | Flutter 3.47.7 / Dart 3.13.5, Gradle 9.3.1, JDK 25 (Android Studio) | Two earlier Gradle builds crashed with *out of memory*: the daemon asked for `-Xmx8G` on a 7.4 GB laptop. `android/gradle.properties` is now capped at 1.5 GB, 2 workers. |
| Screens | Home, Prepare, Safe Places, matching `Tolong_Screen_Descriptions.pdf` | Visually faithful to the PDF. |
| Data | Everything hardcoded: "Mia", "78%", "2 days", the flood alert, "San Roque Covered Court", "1.2 km · 18 min" | The alert, readiness score and shelter were fabricated sample content shown as if real. |
| Buttons | Save progress, Start navigation, header bell/radio, help icon, "View household readiness", Help tab | All dead or misleading. |
| Architecture | `setState` only, no routing, no persistence, no backend | `lib/views`, `lib/widgets`, flat files. |
| Tests | Flutter's counter template (failed to compile) | |
| Reusable pieces | Theme colours/typography, Logo, Character (SVG mascot with poses), CardBox, IconTile, warning-sound generator | Kept and reused. |

## 2. Recommended architecture

- **State:** Riverpod 3 (`Notifier` / `AsyncNotifier`, no code generation, which keeps builds light on 8 GB machines).
- **Navigation:** go_router 18 with a `StatefulShellRoute` for the four tabs and a pure `redirectFor()` function for auth/onboarding/guest rules (unit-tested).
- **Layers per feature:** `data/` (repositories), `domain/` (models), `application/` (controllers), `presentation/` (screens).
- **Local-first storage:**
  - Phase 1: `flutter_secure_storage` (Android Keystore-encrypted) for profile, household, contacts; `shared_preferences` for non-sensitive flags.
  - Phase 2+: Drift (SQLite) for inventory, checklists, alerts, evacuation centers and the sync queue. Encrypt sensitive tables or keep them in secure storage.
- **Backend:** Supabase Auth + Postgres with RLS. Secrets that must not ship in the APK (AI provider keys, any service-role key) live only in Supabase Edge Functions.

## 3. Integration strategies

### Maps (Phase 3)
- **Renderer:** compare `maplibre_gl` (native MapLibre, built-in offline region downloads) and `flutter_map` (pure Dart, simpler, offline through tile caching). Pick after a one-day spike on the target phone.
- **Tiles:** do **not** bulk-download from public openstreetmap.org tile servers. Options to evaluate: a Quezon City **Protomaps PMTiles** extract (single file, can be self-hosted on Supabase Storage and downloaded once for offline use), or a commercial free tier (MapTiler, Stadia). Show OSM attribution on the map.
- **Boundary:** the official QC administrative boundary from a published source (PSA PSGC codes; HDX/OCHA Philippines admin boundaries). Verify licence and accuracy before relying on it; a bounding box is not the boundary.
- **Routing:** the public OSRM demo server is not for production use. Evaluate OpenRouteService or GraphHopper free tiers (walking profile), or self-host OSRM with a QC-only extract. Hazard-aware A* (Phase 6) needs a local road graph plus validated hazard layers.
- **Evacuation centers:** request structured data from QC DRRMO / QC Government. Until then, use a small dataset clearly labelled *development data, not verified*.

### Tol AI assistant (Phase 5)
- Provider-agnostic interface in the app; one Supabase Edge Function (`tol-chat`) holds the API key and calls the chosen provider.
- Compare Gemini, OpenAI and Claude on current pricing, free tier, Filipino quality, latency and data-use terms. **Check the live terms when deciding; they change often.**
- System prompt and server-side checks forbid inventing hazards, shelters, hotlines or weather; Tol cites data source and freshness for anything dynamic.
- Offline: rule-based FAQ and checklist helper, visibly labelled "Offline guidance".

### Offline (Phase 4)
- Sync queue table (operation, entity, local id, payload, attempts, last error). Retry on connectivity *hint*, then confirm with a real request.
- Conflict rule: last-writer-wins per record using server `updated_at`, with deleted records tombstoned so they can't reappear.
- Bundle the DM Sans and Fraunces fonts as assets (they currently download on first launch through google_fonts).

## 4. Phase plan

| Phase | Scope | Status |
|---|---|---|
| 0 | Audit | Done |
| 1 | Theme tokens, splash, welcome, Supabase auth, onboarding, navigation, profile, logout, emergency (guest) access, animations | **Done in code. Supabase sign-up/login still untested end to end; needs a Supabase project.** |
| 2 | Real readiness score, Supply Coverage, interactive checklist, household editing polish, Settings, English/Filipino | **Done in code. Not yet run on a phone.** |
| 3 | Real QC map, GPS, search, center markers, online routing, navigation screen | **Done in code.** Needs the route service deployed, official center data, and real-phone testing |
| 4 | Offline readiness center, map downloads, sync queue, offline guidebook | **Done in code.** Sync needs the Supabase project; guidebook content needs sourced material |
| 5 | Tol chat, Edge Function, offline fallback | **Done in code.** Needs an AI provider key in Supabase secrets |
| 6 | Hazard layers, hazard-aware routing, shelter ranking | Blocked on datasets |
| 7 | Full testing, accessibility review, release build | Planned |

## 5. Phase 1 checklist

### Completed
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

## 6. Phase 2 checklist

### Completed
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

### Not done / limitations
- [ ] Sign-up, login, email verification, password reset and account deletion not yet run against a real Supabase project
- [ ] Household, contacts, supplies and checklist are local-only (encrypted on device); cloud sync comes with the sync queue (Phase 4)
- [ ] Onboarding completion is stored on the device, so logging in on a second phone repeats onboarding (prefilled)
- [ ] Barangay is free text; replace with the official list of 142 QC barangays from PSA PSGC
- [ ] Notification switches store preferences only; reminders need `flutter_local_notifications` (planned with alerts)
- [ ] Filipino translations were written for natural everyday Filipino, but should be reviewed by the team before the defense
- [ ] Disaster Guidebook and Offline Readiness still show "Coming soon" (Phase 4)
- [ ] Fonts download at first launch (bundle them in Phase 4)
- [ ] App ID is still `com.example.tolong_flutter`; choose the final ID before any release build

## 6b. Phase 3 checklist

### Completed
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

### Remaining in Phase 3
- [ ] Deploy `tol-route` and set `ORS_API_KEY` (needs the Supabase project and a free openrouteservice.org key)
- [ ] Replace demo centers with QC DRRMO data
- [ ] Test on a real Android phone: GPS, map gestures inside the scrolling page, the offline download in airplane mode, performance
- [ ] Cross-check barangay names against the PSA PSGC publication (the OSM PSGC codes make this a simple join)

## 6c. Phase 4 checklist

### Completed
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

### Not done / limitations
- [ ] Not run against a real Supabase project yet (migration 3 must be applied)
- [ ] On a new phone, onboarding still runs once before the first pull restores household data
- [ ] Sync is disabled on web (the web preview has no on-device database)
- [ ] Guidebook content must be written from cited official sources (NDRRMC, QC DRRMO, PAGASA, PHIVOLCS, Red Cross) and reviewed
- [ ] Hazard alerts have no data source yet, so nothing is cached for offline use

## 6d. Phase 5 checklist

### Completed
- [x] Provider comparison with sources and a recommendation (`docs/TOL_AI_OPTIONS.md`): Claude Haiku 5.5 for production (≈$0.0003 per reply, API data not trained on by default), Gemini Flash-Lite free tier for zero-cost development with household context off.
- [x] **`tol-chat` Edge Function** (`supabase/functions/tol-chat`): provider adapters for Anthropic, Gemini and OpenAI chosen by `TOL_PROVIDER`/`TOL_MODEL` secrets; API key never in the app; JWT required (signed-in users only); per-user burst limit; input limits (12 messages, 1,000 chars each, 6,000 total); 25 s timeout; clear error codes.
- [x] **Safety**: system prompt forbids inventing hazards, rescues, shelter availability, weather, routes-as-safe and phone numbers; tells the model what the app really has (no live alerts, unverified centers, no guidebook content yet); emergencies → 911 and officials first. **Output guard** removes any 7+ digit number from replies (911 survives). Every online reply is labelled "AI-generated · may be wrong · not an official advisory".
- [x] **Consent**: household summary (size, children/seniors/pets yes/no, whether there are assistance needs, barangay, readiness, missing supply categories) is sent only when the user turns it on (chat menu or Settings → Privacy). Names, ages, phone numbers, contacts and medicine names are never sent (tested). `TOL_SHARE_CONTEXT=false` can force it off server-side.
- [x] **Offline Tol** (`features/tol/domain/offline_guide.dart`): keyword intents in English and Filipino, checked in safety order (emergency, then "is something happening now" → PAGASA/QC DRRMO, then hazard guides, go-bag, water, food, expiry, readiness, evacuation, contacts, greeting). Answers come only from saved data (checklist, supply coverage, readiness, contacts, guidebook status) and are labelled "Offline guidance". It is explicitly not a language model.
- [x] Online → offline fallback with "Try online again"; guests and unconfigured builds use offline mode with an explanation.
- [x] **Chat UI**: floating Tol button (gentle bob, stops under reduced motion, hidden on Safe places so it never covers map controls), chat screen with bubbles, typing indicator, suggested questions, online/offline status, clear conversation with confirmation. History kept encrypted on device (last 60 messages).
- [x] Fixed a reduced-motion bug found while testing: onboarding "Next" now jumps instead of animating with a zero duration.
- [x] 93 automated tests.

### Not done / limitations
- [ ] Needs `supabase functions deploy tol-chat` plus a provider key
- [ ] Filipino answer quality of the chosen model should be checked by the team with real questions
- [ ] Rate limiting is per Edge Function instance (best effort); add a table-based quota if the app goes public

## 6e. Phase 6 — skipped for now
Hazard-aware routing (A* over a QC road graph with flood/hazard layers) was deferred by the team
on 2026-10-18, together with the Supabase setup. Walking routes still use OpenRouteService via
`tol-route` once it is deployed, with the "not a safety guarantee" wording.

## 6f. Phase 7 checklist (testing and optimisation)
Full results: `docs/TEST_REPORT.md`.

### Completed
- [x] Fonts bundled (DM Sans, Fraunces variable, OFL licences shown in Settings → Open-source licenses); `google_fonts` removed, so text renders offline and nothing is fetched at start-up.
- [x] Responsive tests for every route at 320 dp, in Filipino with larger text; overflows fixed.
- [x] Accessibility tests (48 dp tap targets, labelled controls, WCAG AA contrast) on 12 screens; all fixes made.
- [x] Error-state tests: unreadable bundled data, failed offline map download.
- [x] Flood-alert audio player created lazily.
- [x] Release APK build and size check.
- [x] 145 automated tests, `flutter analyze` clean.

### Not done
- [ ] Real-device pass (GPS, offline map in airplane mode, TalkBack, performance on a low-end phone)
- [ ] Everything that needs Supabase (auth, sync, routes, Tol online)
- [ ] Set the real `applicationId` and a release signing key before distribution

## 7. Risks and realistic limits
- **8 GB laptop:** Android builds are slow and can run out of memory. Close other apps; keep the Gradle heap at 1.5 GB. Run tests with `flutter test --concurrency=1`; parallel test engines exhaust memory.
- **Data availability:** hazard-aware routing and shelter evaluation depend on datasets the team does not have yet.
- **Free tiers:** map tiles, routing APIs, Supabase and AI providers all have limits; a demo is fine, a public launch is not.
- **Safety wording:** no "safe route" or live-flood claims without validated, current data.

## 8. Decisions for the team
1. Create the Supabase project (free tier), run both migrations, and share the URL and publishable key via `env.json`, never via git.
2. ~~Help vs More tab~~: confirmed **More** (2026-10-18).
3. ~~Feature-folder move~~: confirmed and done in Phase 2.
4. Initialise git (`git init`) so every change can be reviewed and reverted. Still recommended.
5. Phase 3 needs a decision on the map tile source and routing service (see section 3).
