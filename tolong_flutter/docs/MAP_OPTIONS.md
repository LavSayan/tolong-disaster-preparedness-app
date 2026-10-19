# Phase 3 — Map tiles and routing for Quezon City

Researched 2026-10-18. Free tiers and policies change; re-check the linked pages before release.

## Recommendation in one paragraph

Use **MapLibre (`maplibre_gl`) with OpenFreeMap vector tiles** for the map, and download the Quezon City area with MapLibre's built-in offline regions (well inside OpenFreeMap's offline limit). For routes, use **OpenRouteService (walking and wheelchair profiles)** called through a **Supabase Edge Function** so the API key never ships in the APK. In parallel, build our own **Quezon City walking graph from OpenStreetMap with an A\* search in Dart**. It is what makes offline routing and hazard-aware routing (Phases 4 and 6) possible, and it's the strongest intelligent-agent piece to defend. Everything here is free for a student project and allows commercial use, except where noted.

## 1. Map renderer

| | `maplibre_gl` 0.27.1 | `flutter_map` 8.3.2 |
|---|---|---|
| License | BSD-3 | BSD-3 |
| Rendering | Native MapLibre GL, vector tiles, smooth camera animations | Pure Dart, raster tiles by default; vector tiles need extra plugins |
| Offline download | **Built in** (Android/iOS): download a bounding box + zoom range | Needs `flutter_map_tile_caching`, which is **GPL-3.0** (or a paid commercial license) |
| PMTiles (single-file maps) | Supported | Via third-party plugins |
| Requirements | Flutter ≥ 3.29, Android API 21+, **JDK 21** for Android builds | Very light |
| Fit for TolongApp | Matches the prompt's MapLibre recommendation; offline is first-class | Simpler, but offline would pull a GPL dependency into the app |

**Choose `maplibre_gl`.** We're on Flutter 3.47 and Gradle already uses Android Studio's JDK 25 (≥ 21). It is heavier to build than flutter_map, so expect a longer first Android build on the 8 GB laptop.

## 2. Map tiles

| Option | Cost / limits | Commercial use | Offline allowed | Key needed | Notes |
|---|---|---|---|---|---|
| **OpenFreeMap** (public instance) | Free, no request limits | Yes | **Yes**, each download ≤ 3,000 tiles or 50 MB, ≤ 4 parallel requests, unique User-Agent | No | MIT, self-hostable, styles Positron/Bright/Liberty. No SLA; donation-funded |
| Protomaps PMTiles extract (self-hosted) | Free data (ODbL); we pay only for storage (Supabase Storage free tier) | Yes | Yes, it's a file we own | No | Most robust: one `pmtiles extract` for QC, ship or download it. Needs a CLI step and hosting |
| MapTiler Cloud Free | 5,000 sessions + 100,000 requests / month, then **service pauses** | Free plan described as for testing, prototyping and non-commercial use | Not stated | Yes (in APK) | A demo could hit the cap |
| Stadia Maps Free | 200,000 credits / month | **No** | Not stated for free plan | Yes | Ruled out by its non-commercial terms |
| tile.openstreetmap.org | Volunteer servers | Restricted | **No, offline use is banned** | No | Fine for a browser, not for this app |

**Why OpenFreeMap fits our offline need:** vector tiles stop at zoom 14 and are overzoomed beyond that. Quezon City's bounding box (about 0.16° × 0.19°) is on the order of 100–200 tiles from zoom 0 to 14. That's far below the 3,000-tile cap, so an in-app "Download Quezon City map" is within the published policy. We set a TolongApp User-Agent and show the attribution MapLibre adds (OpenFreeMap © OpenMapTiles, data © OpenStreetMap contributors).

**Fallback:** if OpenFreeMap is down or its policy changes, switch the style URL to a Protomaps PMTiles extract hosted in Supabase Storage. Only one config value changes.

## 3. Routing (Stage A: online)

| Option | Free quota | Commercial | Walking / wheelchair | Can avoid areas | Notes |
|---|---|---|---|---|---|
| **OpenRouteService** (HeiGIT) | **2,000 directions/day, 40/min**, "free for everyone" | Yes | Yes: `foot-walking`, `wheelchair` | **`avoid_polygons`**, useful for hazard zones in Phase 6 | Needs an API key → proxy through a Supabase Edge Function |
| OSRM demo server | ≤ 1 request/s | **Non-commercial, reasonable use only**, no guarantees | Car, foot, bike | No | OK for a quick experiment, not for the app |
| GraphHopper Free | 500 credits/day, 5 points/request | **No** | Limited profile set | Yes (paid features) | Ruled out by its non-commercial terms |
| Valhalla (FOSSGIS public) | Public demo server | Usage terms couldn't be retrieved | Pedestrian | Yes | Don't rely on it without reading the terms |
| Self-host OSRM/Valhalla/ORS | Unlimited | Yes | Configurable | Yes | Needs a server; not worth it for a student budget |

**Choose OpenRouteService, with an Edge Function in front.** Its key would be extractable from the APK, so the app calls `tol-route` on Supabase, which adds the key, enforces a per-user rate limit, and returns distance, duration and the line geometry. The 2,000/day free quota is plenty for a class demo and pilot.

## 4. Offline and hazard-aware routing (Stages B–C): our own A\*

### 4a. Done: the NOAH hazard overlay (rendering, not routing)

The map can now overlay **modelled** hazard from Project NOAH, bundled in `datasets/`:

| Archive | Size | Zoom | Tiles | Bounds |
|---|---|---|---|---|
| `qc_flood.pmtiles` | 51.1 MB | 0–14 | 169 | 120.9697,14.5691 → 121.1538,14.7964 |
| `qc_base.pmtiles` | 30.1 MB | 0–15 | 583 | same |

Both are PMTiles v3, produced by `tippecanoe -z14` per layer then `tile-join -pk` across the nine
NOAH layers, and then clipped from the 5.17 GB national archive (81,712 tiles) with
`pmtiles extract --bbox`. **They are committed to git on purpose** so members get the data
without re-downloading; the repo is ~78 MB.

Nine source layers are exposed to users as four hazard groups, because that is how many choices a
stressed person can act on, and it matches the guidebook's taxonomy:

| Group | Source layers | Severity attribute | Quezon City |
|---|---|---|---|
| Flood depth | `flood_5yr`, `flood_25yr`, `flood_100yr` | `Var` 1–3 | present |
| Landslide | `landslide` | `HAZ` 1–4 | present |
| Storm surge | `storm_surge_ssa1`…`ssa4` | `HAZ` 1–3 | **absent — coastal only** |
| Debris flow | `debris_flow` | `HAZ` 3–4 | sparse |

The attribute column is **not documentation from the source — it is read out of the archive**.
Both `Var` and `HAZ` are stored as **numbers** (ints), verified by decoding every tile of
`qc_flood.pmtiles`; the observed value sets per layer are pinned in
`test/fixtures/hazard_archive_fields.json`, regenerated by
`python tools/hazard_archive_check/hazard_fields.py --extract` and re-verified by `--check`.
That fixture is why the severity filter **must compare numbers**: MapLibre's `==` compares types
strictly, and `1 == '1'` is false. An earlier filter compared string codes against the numeric
attribute, matched nothing, painted no fills, and threw no error — the legend rendered over a
blank map, which read as a transport failure for days before the real cause was found.
`hazard_layer_test.dart` asserts the codes are ints, `hazard_archive_fields_test.dart` asserts
every code the data carries has a declared band, and `classifyDraw` (below) reports it at run
time if a filter ever matches nothing again.

**Honest limits, enforced by tests:**
- This is *modelled scenario* data, not live conditions. The legend says so, and never says
  "safe" — only "lower known flood exposure", per step 4 below.
- NOAH models **no earthquake and no fire**. The legend states the gap rather than implying full
  coverage.
- The archive's own `tilestats` still report the *national* feature counts and its `name` /
  `antimeridian_adjusted_bounds` fields are stale leftovers from the source. Never surface those;
  read real bounds from the header (`pmtiles show`).

Implementation notes:

- `map_style.dart` exposes `BasemapStyle`, currently `openFreeMap` (hosted, unchanged). Flipping
  `BasemapStyle.current` to `localPmtiles` switches the basemap to the bundled file — one value, no
  widget changes. Offline region downloads read the same field. **That switch is not verified yet:**
  the *hazard overlay's* transport is handled per platform (below), but the basemap archive has
  never been wired beyond the constant.
- **The archive URL needs three slashes: `pmtiles:///…`.** The pmtiles library looks a style source
  up by stripping exactly ten characters — the length of `pmtiles://` — off its URL and matching the
  remainder against the key the archive was registered under. Write `pmtiles://assets/…` and the
  lookup misses, so the library silently builds a *second* archive and re-reads 51 MB.
  `hazardArchiveKey` is the one constant both sides are derived from (`map_style.dart`), and
  `hazard_layer_test.dart` asserts the equality.
- **How each platform reads the archive** (`hazard_archive.dart`, called once from `main()`):
  - **Web**: the pmtiles library is **vendored** at `web/vendor/pmtiles-4.3.0.js` (BSD-3-Clause,
    Protomaps), not loaded from a CDN — a CDN on the boot path could stop the app launching at all.
    `vendor/hazard_archive.js` (our glue) fetches the archive once, wraps it in a `File`-backed
    pmtiles `FileSource` named `hazardArchiveKey`, and registers the `pmtiles://` protocol with
    `maplibregl.addProtocol`. A conditional import (`hazard_protocol*.dart`) keeps `dart:js_interop`
    out of mobile builds.
  - **Android and iOS**: MapLibre Native reads `pmtiles://` only from a **seekable file**, and a
    bundled asset is deflated inside the APK with no filesystem path — so on first run the app
    copies the archive into the app-support directory (atomic `.part` + rename) and the map reads
    `pmtiles://<that path>`. The copy persists across launches; bump the extraction filename in
    `hazard_archive.dart` when the bundled data changes, so installed devices re-extract.
- **Why not pmtiles' HTTP `FetchSource` on web:** it requires the server to honour byte ranges, and
  `flutter run -d chrome` — like any plain static file server — answers a `Range` request with a 200
  carrying the whole 51 MB, which the library rejects. The whole-file source removes that
  dependency; the cost is one 51 MB fetch per page load, on first overlay use.
- **Preparation must never be able to crash start-up.** It is wrapped and reports `null` on failure.
  `main()` records the outcome via `setPmTilesRegistered` / `setHazardArchiveUrl`, and
  `hazardLayerStatusProvider` turns a failure into `HazardProtocolMissing`. The picker then disables
  the groups and says so — it never removes the control, because a hidden button leaves the user
  with no idea why the overlay is missing.
- Sources and layers are added in `onStyleLoaded`, never `onMapCreated`: MapLibre discards
  runtime-added layers when the style is replaced.
- Added layer ids are tracked in the widget state, not read back from the style, which would mean
  parsing the whole style JSON on every change.
- **The "nothing drawn" pin (`onMapIdle` → `classifyDraw`).** Silence is how the filter bug
  survived, so the map now checks itself: on each idle frame with an active group it queries the
  source unfiltered and again under `hazardGroupFilterExpression(group)`. Loaded features with
  zero matches report `filterMatchedNothing`, which the legend renders as a data note
  (`hazardNothingDrawn`) — it never reads "no hazard here". An empty view reports `viewHasNoData`
  and stays quiet, because QC stretches without a flood polygon are normal. The counts are also
  printed in debug builds.

**Verification status (2026-10-20):** in Chrome (`flutter run -d chrome`, guest → Safe places →
hazard button) the picker, legend and layer registration all worked but the colours did not. Two
independent causes, both found and fixed the same day: the first request showed no error and no
colours because of the string-vs-number filter (above), and the dev server legitimately cannot
byte-serve, so the original pmtiles `FetchSource` would have failed with a loud error. With both
fixes loaded from a full restart, **the colours render and the `hazardNothingDrawn` note stays
hidden** (verified by re-running the check in Chrome). Still open: the Android extraction path
awaits its first device check.

| Symptom | Cause |
|---|---|
| Hazard colours appear, no console notes | Verified 2026-10-20 (after a one-time 51 MB fetch on web) |
| Legend appears, no colours, **no error** | Severity filter type mismatch (string vs number) — should now warn via `hazardNothingDrawn` |
| Button absent | Reverted the gate by hand |
| 404 on `/assets/datasets/qc_flood.pmtiles` | Web path wrong |
| *"storage backend supports HTTP Byte Serving"* | A `FetchSource` slipped back in; the server does not honour `Range` |
| *"Invalid PMTiles protocol URL"* | `pmtiles.js` did not load, or registration failed |

**Outstanding:** the NOAH reuse licence is unconfirmed (see §5). Ask UP Resilience Institute
before distributing. The data is usable for evaluation; it is not cleared for release.

### 4b. Still to build: hazard-aware A\* routing

Map tiles alone can't compute a route offline. The plan:

1. Download the Philippines extract from Geofabrik (OSM, ODbL) and cut it to the QC boundary with `osmium`.
2. Run a small Python script once (offline, in the repo's `tools/`) that keeps walkable ways and writes a compact graph asset: nodes with lat/lon, edges with length and flags (steps, bridge, unpaved).
3. In the app, run **A\*** with straight-line (haversine) distance as the heuristic, with **Dijkstra** kept as a baseline for the report.
4. Add hazard weights per edge, e.g. extra cost for edges inside NOAH 100-year flood polygons, and excludes verified closures. The UI would say "lower known flood exposure", never "safe".

Steps 1–3 do not exist yet; step 4's hazard weights are now unblocked, because the flood polygons
finally ship with the app. This gives TolongApp a real, explainable routing agent that works in airplane mode. We will measure the graph size for QC before committing to shipping it in the APK versus downloading it.

**Shelter ranking (Phase 6), built on the same hazard data:** the trained ranking model — task,
features, pairwise dataset, training, export and evaluation — is specified in
[`SHELTER_RANKING_ML.md`](SHELTER_RANKING_ML.md).

## 5. Data sources and their status

| Data | Best source found | Status |
|---|---|---|
| QC boundary | OSM relation for Quezon City (ODbL), or HDX "Philippines – Subnational Administrative Boundaries" (NAMRIA/PSA via OCHA, files dated Nov 2023, levels incl. barangay) | HDX licence **not confirmed**; HDX itself calls these indicative, not official. Use OSM for display, cross-check with HDX |
| Barangay list (142) | PSA PSGC | To import; replaces the free-text field |
| Evacuation centers | QC government evacuation center pages and QC DRRMO earthquake evacuation guide; a UP Diliman study found **no centralized, up-to-date database** for Metro Manila | **No machine-readable official list found.** Email **qcdrrmo@quezoncity.gov.ph** for a CSV. Until then: a small dataset labelled *development data, not verified* |
| Flood hazard, landslide, storm surge, debris flow | UP NOAH hazard maps (5-100-year rainfall scenarios, shapefiles; QC map validated in 2022) | **Downloaded, clipped to QC and bundled** as ``datasets/qc_flood.pmtiles`` (see 4a). **Reuse licence still not stated** - ask UP Resilience Institute before distributing |

## 6. Costs and risks

- **Cost:** ₱0 on these plans for a demo and pilot. Supabase free tier covers the Edge Function and storage.
- **No SLAs:** OpenFreeMap and OpenRouteService free tiers can be slow or down. The app must handle that (cached tiles, "routing unavailable" state, offline A\* later).
- **Quota exposure:** never put the ORS key in the APK; rate-limit in the Edge Function.
- **Data truthfulness:** demo evacuation centers stay labelled until QC DRRMO data arrives.
- **Build weight:** `maplibre_gl` adds native libraries; first Android build will be slower on the 8 GB laptop.

## 7. Proposed Phase 3 build order

1. Add `maplibre_gl` + `geolocator`; replace the illustration with a real map centered on QC, OSM attribution, zoom/recenter/reset controls, location permission flow, and graceful handling outside QC.
2. Evacuation center model + labelled development dataset + markers + detail sheet.
3. `tol-route` Edge Function (ORS foot-walking/wheelchair) + route polyline, distance and time, with loading/error/offline states.
4. Navigation screen: live location along the route, end navigation, clear "route preview, not turn-by-turn" wording.
5. Barangay search using the PSGC list and the QC boundary.
6. "Download Quezon City map" offline region (feeds the Phase 4 Offline Readiness Center).

## Sources

- maplibre_gl: https://pub.dev/packages/maplibre_gl
- flutter_map: https://pub.dev/packages/flutter_map · flutter_map_tile_caching (GPL-3.0): https://pub.dev/packages/flutter_map_tile_caching
- OSM tile usage policy: https://operations.osmfoundation.org/policies/tiles/
- OpenFreeMap: https://openfreemap.org/
- MapTiler pricing: https://www.maptiler.com/cloud/pricing/
- Stadia Maps pricing: https://stadiamaps.com/pricing/
- Protomaps downloads: https://docs.protomaps.com/basemaps/downloads
- OSRM demo server: https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server
- OpenRouteService plans: https://openrouteservice.org/plans/
- GraphHopper pricing: https://www.graphhopper.com/pricing/
- FOSSGIS server policy: https://wiki.openstreetmap.org/wiki/FOSSGIS/Server/Policy
- HDX Philippines boundaries: https://data.humdata.org/dataset/philippines-administrative-levels-0-to-3
- QC evacuation centers: https://quezoncity.gov.ph/evacuation-centers · https://quezoncity.gov.ph/qcitizen-guides/qc-earthquake-evacuation-centers/
- UP Diliman evacuation center study: https://isprs-archives.copernicus.org/articles/XLII-3-W8/79/2019/isprs-archives-XLII-3-W8-79-2019.pdf
- UP NOAH: https://resilience.up.edu.ph/updating-of-up-noah-flood-maps-to-continue-in-2025
