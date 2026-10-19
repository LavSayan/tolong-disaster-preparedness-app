# TolongApp

Calm, offline-first disaster preparedness for every household.

TolongApp helps a family get ready before a disaster: it tracks supplies and go-bag
readiness, scores household preparedness, and finds evacuation routes — all working
without a network connection.

## Platform

Android. The app is offline-first: everything works with no account and no connectivity.
Backed by Supabase for auth and optional multi-device sync.

## Quick start

```bash
cd tolong_flutter
cp env.example.json env.json     # add your Supabase URL + publishable key
flutter pub get
flutter run
```

The app runs fully offline without `env.json` — features that need a backend fail
honestly with an explicit error rather than pretending to work.

See [`tolong_flutter/docs/SETUP.md`](SETUP.md) for the full setup,
including Supabase deployment and API keys.

## Tests

```bash
cd tolong_flutter
flutter test --concurrency=1     # 195 passing; --concurrency=1 is mandatory
flutter analyze                   # clean
```

Parallel test engines exhaust memory on the target machines.

## Documentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — how the code is organised, and why
- [`STRUCTURE.md`](STRUCTURE.md) — "I want to change X → open these files"
- [`tolong_flutter/docs/SETUP.md`](SETUP.md) — local setup and backend deploy
- [`tolong_flutter/docs/ROADMAP.md`](ROADMAP.md) — status and known gaps
- [`tolong_flutter/docs/TEST_REPORT.md`](TEST_REPORT.md) — what is and isn't tested
- [`tolong_flutter/docs/MAP_OPTIONS.md`](MAP_OPTIONS.md) — map data & routing choices, incl. the NOAH hazard overlay (§4a)

## Security note

`env.json` holds only a Supabase publishable (anon) key, protected by Row Level Security.
Never put a service-role key or an AI provider key in it — anything compiled into the APK
can be extracted. Real secrets live in Supabase function secrets.