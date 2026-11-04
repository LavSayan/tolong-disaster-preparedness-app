# TolongApp

Calm, offline-first disaster preparedness for every household.

TolongApp helps a family get ready before a disaster: it tracks supplies and go-bag
readiness, scores household preparedness, and finds evacuation routes — all working
without a network connection.

## Platform

Android first (web is a secondary build target). The app is offline-first:
everything works with no account and no connectivity. Backed by Supabase for auth
and optional multi-device sync.

## Quick start

```bash
cd tolong_flutter
cp env.example.json env.json     # add your Supabase URL + publishable key
flutter pub get
flutter run
```

The app runs fully offline without `env.json` — features that need a backend fail
honestly with an explicit error rather than pretending to work.

See [`tolong_flutter/docs/SETUP.md`](tolong_flutter/docs/SETUP.md) for the full setup,
backend deployment and API keys.

## Tests

```bash
cd tolong_flutter
flutter test --concurrency=1     # 195 passing; --concurrency=1 is mandatory
flutter analyze                   # clean
```

Parallel test engines exhaust memory on 8 GB machines.

## Documentation

- [`tolong_flutter/docs/SETUP.md`](tolong_flutter/docs/SETUP.md) — local setup, backend deploy, manual QA checklist
- [`tolong_flutter/docs/CODE_GUIDE.md`](tolong_flutter/docs/CODE_GUIDE.md) — how the code is organised and why; "I want to change X → open these files"
- [`tolong_flutter/docs/STATUS.md`](tolong_flutter/docs/STATUS.md) — current status, what is verified, known gaps, next steps
- [`tolong_flutter/docs/CHANGELOG.md`](tolong_flutter/docs/CHANGELOG.md) — phase-by-phase history and dated test-report updates
- [`tolong_flutter/docs/design/MAP_OPTIONS.md`](tolong_flutter/docs/design/MAP_OPTIONS.md) — map data & routing choices, incl. the NOAH hazard overlay (§4a)
- [`tolong_flutter/docs/design/TOL_AI_OPTIONS.md`](tolong_flutter/docs/design/TOL_AI_OPTIONS.md) — Tol assistant provider options
- [`tolong_flutter/docs/design/SHELTER_RANKING_ML.md`](tolong_flutter/docs/design/SHELTER_RANKING_ML.md) — shelter-ranking specification

Also at the repo root: `tools/` — `hazard_archive_check` and `psgc_crosscheck`, plain-Python
fixture guards run with `--check` (no dependencies).

## Security note

`env.json` holds only a Supabase publishable (anon) key, protected by Row Level Security.
Never put a service-role key or an AI provider key in it — anything compiled into the APK
can be extracted. Real secrets live in Supabase function secrets.
