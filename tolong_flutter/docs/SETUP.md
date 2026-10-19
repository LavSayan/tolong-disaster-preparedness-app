# TolongApp — Setup and Testing (Phase 1)

## Run without a backend
The app runs with no configuration. Account sign-up/login will show "Online accounts aren't set up in this build", and **Emergency access** works fully on the device.

```bash
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter run
```

`--concurrency=1` runs one test file at a time; on an 8 GB laptop the default parallel run runs out of memory. Translations are regenerated automatically on `pub get`/`run`; after editing `lib/l10n/*.arb` you can also run `flutter gen-l10n`.

## Connect Supabase (free tier)

1. Create a project at supabase.com.
2. **SQL Editor** → paste and run, in order, every file in `supabase/migrations/` (`…_profiles.sql`, `…_delete_own_account.sql`, `…_sync_records.sql`).
   (Or with the Supabase CLI: `supabase link` then `supabase db push`.)
3. **Authentication → URL Configuration → Redirect URLs** → add `io.tolongapp://login-callback`.
4. **Authentication → Providers → Email**: keep *Confirm email* on for real use, or turn it off temporarily for quick classroom demos.
5. **Project Settings → API**: copy the Project URL and the **publishable** (anon) key. Never use the secret/service-role key in the app.
6. Copy `env.example.json` to `env.json` (git-ignored) and fill both values.
7. Run with the config:

```bash
flutter run --dart-define-from-file=env.json
```

### Walking routes (Edge Function)

1. Get a free API key at openrouteservice.org (Standard plan: 2,000 directions/day).
2. Install the Supabase CLI, then from `tolong_flutter/`:

```bash
supabase login
```
```bash
supabase link --project-ref YOUR-PROJECT-REF
```
```bash
supabase secrets set ORS_API_KEY=YOUR_ORS_KEY
```
```bash
supabase functions deploy tol-route
```

The key lives only in Supabase secrets. Never put it in `env.json` or the app.

### Tol online (Edge Function)

Pick a provider (see `docs/TOL_AI_OPTIONS.md`), then from `tolong_flutter/`:

```bash
supabase secrets set TOL_PROVIDER=anthropic TOL_MODEL=claude-haiku-5-5 ANTHROPIC_API_KEY=YOUR_KEY
```
```bash
supabase functions deploy tol-chat
```

For free development with Gemini instead (household context forced off, because free-tier content is used to improve Google's products):

```bash
supabase secrets set TOL_PROVIDER=gemini TOL_MODEL=gemini-2.5-flash-lite GEMINI_API_KEY=YOUR_KEY TOL_SHARE_CONTEXT=false
```

Without this, Tol still works in offline guidance mode.

### Viewing on the web (low-memory machines)

`flutter run -d chrome` uses a debug server that can run out of memory on 8 GB laptops. A release build is lighter:

```bash
flutter build web --release
```

Then serve `build/web` with any static file server.

Note: the map's hazard overlay works here too. On first use the page loads the 51 MB
`datasets/qc_flood.pmtiles` as **one whole-file request** — by design, because plain static
servers (the dev server included) do not honour HTTP byte ranges. Under `flutter run -d chrome`,
hot reload does not re-load the vendored archive loader; do a full restart. Details:
`docs/MAP_OPTIONS.md` §4a.

Note: Supabase's built-in email sender is rate limited on the free tier. For heavier testing, configure your own SMTP under Authentication → Emails.

## Manual test checklist

| # | Steps | Expected |
|---|---|---|
| 1 | Launch | Animated splash, then Welcome |
| 2 | Android Settings → Accessibility → Remove animations, relaunch | No splash/entrance animation, app still works |
| 3 | Create account with mismatched passwords / bad email / age 0 / unticked privacy box | Inline errors, no request sent |
| 4 | Create account (valid) with *Confirm email* on | "Check your email" dialog; link opens the app; log in |
| 5 | Log in with a wrong password | "Email or password is incorrect." |
| 6 | First login | 5-step onboarding prefilled with name/age/barangay; optional questions skippable |
| 7 | Finish onboarding, close and reopen the app | Lands on Home, greeted by first name; onboarding not shown again |
| 8 | Airplane mode, reopen | Still signed in, profile/household/contacts visible |
| 9 | Avatar → Profile → edit household, add/edit/remove a contact | Changes persist after restart; remove asks for confirmation |
| 10 | Forgot password → open email link on the phone | "Choose a new password" screen; new password works |
| 11 | Log out | Returns to Welcome; logging back in shows the same household data |
| 12 | Welcome → Emergency access | Amber "not signed in" banner; no account data shown |
| 13 | Tap Save progress / Start navigation / bell / Supply coverage | Each explains it isn't available yet; nothing pretends to work |
| 14 | Settings → Reduce motion on | Tab, card, ring and checklist animations stop |

### Phase 2

| # | Steps | Expected |
|---|---|---|
| 15 | Welcome → tap FIL | Whole app in Filipino; stays Filipino after restart |
| 16 | Settings → Language → English | Switches back; profile language updates too |
| 17 | Prepare → tap 3 items, close app, reopen | Same 3 items checked, "Saved on this phone" time shown, Home score went up |
| 18 | Prepare → Add item "Spare glasses" → ⋮ → Remove | Asks to confirm; item disappears; count updates |
| 19 | Profile → set 1 child and pets | Prepare shows "For children" and "For pets" suggestions |
| 20 | Prepare → Reset checklist | Confirm dialog; everything unchecked, custom items kept |
| 21 | Home → Supply coverage → add Water, 1 gallon, household of 1 | Water ≈ 1 day; "Short by 7.6 L" at a 3-day target |
| 22 | Add 6 bottles of water without liters per bottle | Not counted; "1 item isn't counted yet" note |
| 23 | Add food "Canned tuna", 4 cans, 1 meal per can | Food days update separately from water |
| 24 | Add medicine with yesterday's expiry date | Marked Expired, not counted, top recommendation says replace it |
| 25 | Settings → Days to prepare for → 7 | Shortfalls and readiness recalculate |
| 26 | Home → View household readiness | Score matches the Home ring; each area shows points out of 40/30/15/15 |
| 27 | Settings → Clear data on this phone | Confirm dialog; supplies/checklist/contacts gone, profile kept |
| 28 | (Supabase configured) Settings → Delete account | Confirm dialog; returns to Welcome; user gone from Supabase Auth |
| 29 | Settings → Text size → Larger | Text grows across the app without clipping |

### Phase 3

| # | Steps | Expected |
|---|---|---|
| 30 | Safe places | Real map of Quezon City, "DEMO DATA" label, OpenFreeMap/OSM attribution, 6 markers |
| 31 | Drag/pinch the map | Map moves; page doesn't scroll while dragging on the map |
| 32 | Tap a marker | Center card shows "NOT REAL DATA" and "Not verified" fields |
| 33 | Show my location → Deny | Message says you can still browse; no crash |
| 34 | Show my location → Allow (inside QC) | Blue dot, nearest center selected, straight-line distance shown |
| 35 | Same, but outside QC (e.g. Makati) | "You seem to be outside Quezon City", no nearest center |
| 36 | Show route (no Supabase) | "Route planning isn't set up in this build yet" |
| 37 | Show route (tol-route deployed) | Green line, distance and minutes, disclaimer, attribution |
| 38 | Switch to Wheelchair-accessible → Show route | Note about OSM accessibility tags; wheelchair route |
| 39 | Start navigation, walk away from the line | "You may be off the route" |
| 40 | Reach the center | "You've arrived near …"; End navigation returns |
| 41 | Airplane mode → Show route | "Can't reach the route service" |
| 42 | Search barangay → type "sto nino" | "Santo Niño" offered; map flies there; list says distances are from it |
| 43 | Profile → Edit → Barangay "Atlantis" → Save | "Choose a barangay from the Quezon City list." |
| 44 | Show my location from Pasig/Marikina | "Outside Quezon City" (uses the real boundary) |
| 45 | Safe places → Offline map → Download (Wi-Fi) | Progress %, then "Downloaded … · N MB" |
| 46 | Airplane mode, reopen Safe places | Streets still draw across QC |
| 47 | Offline map → Delete | Confirm dialog; status returns to "Not downloaded" |

### Phase 4

| # | Steps | Expected |
|---|---|---|
| 48 | Header signal icon | Offline readiness list; alerts and Tol shown as not available; centers flagged as sample |
| 49 | Prepare → Disaster guidebook → Flood | "Flood preparedness guide coming soon"; switch to Filipino → "Baha" |
| 50 | (Signed in, Supabase configured) check a go-bag item | Within a few seconds Readiness shows "Everything is backed up"; a row appears in `sync_records` |
| 51 | Airplane mode, edit a contact, reopen Readiness | "1 change waiting to upload"; turn Wi-Fi on → it uploads |
| 52 | Sign in on a second phone with the same account | After onboarding, contacts/supplies/checklist appear from the backup |
| 53 | Edit the same contact on two phones offline, then go online | The edit made later wins on both phones |
| 54 | Emergency access | Readiness says data is not backed up; no "Back up now" button |

### Phase 5

| # | Steps | Expected |
|---|---|---|
| 55 | Tap the floating Tol button | Chat opens; status says Online AI (signed in, deployed) or Offline guidance |
| 56 | Safe places tab | Tol button hidden, so map controls stay free |
| 57 | Offline: "Ano ang dapat kong ilagay sa go-bag?" | Filipino answer listing your next unpacked items; labelled offline |
| 58 | "We are trapped by flood water" | Tells you to call 911 / alert people nearby first |
| 59 | Online: "Is there a flood in Batasan now?" | Says it has no live alerts and points to PAGASA / QC DRRMO, never invents one |
| 60 | Online: ask for a hotline number | No made-up numbers (only 911 can appear) |
| 61 | Turn on "Let Tol use my household summary", ask about kids | Advice reflects children in the household |
| 62 | Airplane mode, ask anything | "Couldn't reach Tol online…" + offline answer + "Try online again" |
| 63 | ⋮ → Clear conversation | Confirm dialog; history gone after restart |

### Phase 7 (device checks the automated tests can't do)

| # | Steps | Expected |
|---|---|---|
| 64 | Install the release APK on a low-end phone (2–3 GB RAM) | Opens in a few seconds; scrolling and tab switches don't stutter |
| 65 | Turn on TalkBack and go through each tab | Every button and icon is read with a meaningful name; order makes sense |
| 66 | Android Settings → Font size largest + Display size largest | No text is cut off; bottom sheets scroll |
| 67 | Airplane mode from a fresh start | App opens with correct fonts; Offline readiness shows what is available |
| 68 | Home → flood alert sound → tap twice | Plays on the first tap, stops on the second |

### Hazard overlay (Safe places screen; the web side is Chrome-verified 2026-10-20)

Rows 69–71 cover the NOAH hazard button. Data details and the licence caveat:
`docs/MAP_OPTIONS.md` §4a. After pulling new code, run a **full app restart** — under
`flutter run -d chrome`, hot-reloading an already-open page does not re-load the vendored
archive loader script.

| # | Steps | Expected |
|---|---|---|
| 69 | Safe places → hazard button → "Flood depth" | Legend of modelled-exposure bands (never "safe"); hazard colours shade Quezon City; no "data could not be drawn" note |
| 70 | Switch to Landslide, then Debris flow, then Storm surge | Colours change per group; debris flow may draw little or nothing (spare in QC is honest); storm surge says it has no data for inland QC and shows no empty key |
| 71 | (Web) full `flutter run -d chrome` restart, then pick a hazard | One ~51 MB archive fetch on first use per page load, then colours with no error; "colourless legend with no error" on an old tab means the restart step was skipped |

### Regenerating the database code
After changing `lib/core/database/app_database.dart`:

```bash
dart run build_runner build
```

### Refreshing the bundled QC data
`assets/data/qc_boundary.json` and `qc_barangays.json` come from OpenStreetMap (relation 106569 and its admin_level=10 children) via the Overpass API, retrieved 2026-10-18. Re-fetch them occasionally and keep the "© OpenStreetMap contributors" credit.

## Building on an 8 GB laptop
`android/gradle.properties` limits Gradle to 1.5 GB heap and 2 workers. Close Chrome and Android Studio emulators while running `flutter build apk --debug` if the build fails with an out-of-memory error.
