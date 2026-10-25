#!/usr/bin/env python3
"""Join the PHIVOLCS earthquake catalogue to the shelter-ranking sites as context data.

`datasets/phivolcs_datasets/{2016..2022}/*.csv` are monthly PHIVOLCS event logs with the
header `Date - Time, Lat, Long, Depth, Mag, Location`. This tool computes, per ranking site
(the same 142 barangay centroids + 6 demo centres as
`tolong_flutter/assets/data/hazard_bands.json`), the catalogue-derived context metrics and
writes them to `tools/ranking/data/seismic_context.json`.

**This is context, not a ranking weight.** The model's factors are exactly exposure / travel /
accessibility (SHELTER_RANKING_ML.md §3, §5). A 7-year catalogue excerpt is no substitute for
a long-term seismic hazard model, and PHIVOLCS epicentres — mostly offshore or regional — say
nothing about a stationary hazard *at* a site. These numbers exist for dataset authoring
context, provenance disclosures and the evaluation report; the trainer, the app and the
exported weights never read a seismic weight from anywhere.

Per site (haversine great-circle over the catalogue, radius 50 km):
  - eventsWithin50km, eventsMag4Plus (mag >= 4.0)
  - maxMagnitude, meanDepthWithin50km
  - magnitudeWeightedSum = sum of min(mag, 7)^2 over events in radius (energy-style proxy)
  - seismicProximityIndex = magnitudeWeightedSum / peak over all sites, in [0, 1]

Stdlib only, like every tool under `tools/`. Deterministic (sorted output, fixed rounding, no
timestamps), so `--check` is a byte-exact drift guard:
  --extract  (re)build `tools/ranking/data/seismic_context.json` (default)
  --check    re-derive in memory and byte-compare against the committed file
"""

import argparse
import csv
import json
import math
import os
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BANDS_ASSET = os.path.join(REPO_ROOT, "tolong_flutter", "assets", "data", "hazard_bands.json")
PHIVOLCS_DIR = os.path.join(REPO_ROOT, "tolong_flutter", "datasets", "phivolcs_datasets")
OUT_DEFAULT = os.path.join(REPO_ROOT, "tools", "ranking", "data", "seismic_context.json")

RADIUS_KM = 50.0
EARTH_RADIUS_KM = 6371.0


def parse_events():
    """Catalogue events as (lat, lon, depth, mag) tuples; skips rows whose numbers don't parse."""
    files = sorted(
        os.path.join(dirpath, name)
        for dirpath, _dirs, names in os.walk(PHIVOLCS_DIR)
        for name in names
        if name.lower().endswith(".csv")
    )
    if not files:
        raise SystemExit("no PHIVOLCS CSV files under %s" % PHIVOLCS_DIR)
    events = []
    skipped = 0
    for path in files:
        with open(path, encoding="utf-8-sig", errors="replace", newline="") as handle:
            for row_index, row in enumerate(csv.reader(handle)):
                if row_index == 0 or len(row) < 5:
                    continue
                try:
                    lat = float(row[1])
                    lon = float(row[2])
                    depth = float(row[3]) if row[3] else None
                    mag = float(row[4]) if row[4] else None
                except ValueError:
                    skipped += 1
                    continue
                events.append((lat, lon, depth, mag))
    return events, files, skipped


def haversine_km(lat1, lon1, lat2, lon2):
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2)
    return 2 * EARTH_RADIUS_KM * math.asin(min(1.0, math.sqrt(a)))


def site_context(sites, events):
    rows = []
    weights = []
    for site in sites:
        site_lat, site_lng = site["lat"], site["lng"]
        count = 0
        strong = 0
        max_mag = None
        depth_sum = 0.0
        depth_count = 0
        weighted = 0.0
        for event_lat, event_lon, depth, mag in events:
            if haversine_km(site_lat, site_lng, event_lat, event_lon) > RADIUS_KM:
                continue
            count += 1
            if mag is not None:
                strong += 1 if mag >= 4.0 else 0
                if max_mag is None or mag > max_mag:
                    max_mag = mag
                weighted += min(mag, 7.0) ** 2
            if depth is not None:
                depth_sum += depth
                depth_count += 1
        rows.append({
            "id": site["id"],
            "lat": round(site_lat, 6),
            "lng": round(site_lng, 6),
            "eventsWithin50km": count,
            "eventsMag4Plus": strong,
            "maxMagnitude": round(max_mag, 2) if max_mag is not None else None,
            "meanDepthWithin50km": round(depth_sum / depth_count, 1) if depth_count else None,
            "magnitudeWeightedSum": round(weighted, 3),
        })
        weights.append(weighted)
    peak = max(weights) if weights else 0.0
    for row in rows:
        row["seismicProximityIndex"] = round(row["magnitudeWeightedSum"] / peak, 6) if peak > 0 else 0.0
    return rows


def build_document():
    if not os.path.exists(BANDS_ASSET):
        raise SystemExit("%s does not exist yet — run `python tools/ranking/extract_bands.py "
                         "--extract` first; the seismic context joins the same site list."
                         % BANDS_ASSET)
    with open(BANDS_ASSET, encoding="utf-8") as handle:
        sites = json.load(handle)["sites"]
    events, files, skipped = parse_events()
    rows = site_context(sites, events)
    years = sorted({os.path.basename(os.path.dirname(path)) for path in files})
    return {
        "asset": "seismic_context",
        "version": 1,
        "role": "context only — NOT a ranking factor; the model's three factors are exposure, "
                "travel and accessibility (SHELTER_RANKING_ML.md §3)",
        "source": {
            "directory": "tolong_flutter/datasets/phivolcs_datasets/",
            "yearFolders": years,
            "files": sorted(os.path.relpath(f, REPO_ROOT).replace("\\", "/") for f in files),
            "events": len(events),
            "skippedRows": skipped,
        },
        "method": {
            "radiusKm": RADIUS_KM,
            "earthRadiusKm": EARTH_RADIUS_KM,
            "magnitudeWeightedSum": "sum of min(mag,7)^2 over the events within radius",
            "seismicProximityIndex": "magnitudeWeightedSum / peak over all sites",
            "caveat": "a 2016-2022 catalogue excerpt is not long-term seismic hazard; "
                      "epicentre density is a historical proxy, never a safety measure",
        },
        "sites": rows,
    }


def serialize(document):
    return json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--extract", action="store_true", help="rebuild the context file (default)")
    parser.add_argument("--check", action="store_true", help="re-derive in memory and byte-compare; exit 1 on drift")
    parser.add_argument("--out", default=OUT_DEFAULT, help="output path")
    args = parser.parse_args(argv)
    document = build_document()
    if args.check:
        with open(args.out, encoding="utf-8") as handle:
            committed = handle.read()
        if serialize(document) != committed:
            print("seismic_context.json drift detected; rerun: python tools/ranking/seismic_context.py --extract")
            return 1
        print("OK: seismic_context.json matches the PHIVOLCS catalogue (%d events, %d sites)"
              % (document["source"]["events"], len(document["sites"])))
        return 0
    payload = serialize(document)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(payload)
    print("wrote %s (%d bytes) — %d sites from %d events in %d files, years %s"
          % (os.path.relpath(args.out, REPO_ROOT).replace("\\", "/"), len(payload),
             len(document["sites"]), document["source"]["events"], len(document["source"]["files"]),
             ",".join(document["source"]["yearFolders"])))
    with_events = [r for r in document["sites"] if r["eventsWithin50km"] > 0]
    strongest = [r for r in document["sites"] if r["eventsMag4Plus"] > 0]
    print("  sites with any event within %g km: %d; with a M4+ event: %d" % (RADIUS_KM, len(with_events), len(strongest)))
    if with_events:
        top = sorted(document["sites"], key=lambda r: (-r["seismicProximityIndex"], r["id"]))[:5]
        for row in top:
            print("  %s: events=%d mag4+=%d maxMag=%s weightedSum=%.1f index=%.3f"
                  % (row["id"], row["eventsWithin50km"], row["eventsMag4Plus"],
                     row["maxMagnitude"], row["magnitudeWeightedSum"], row["seismicProximityIndex"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
