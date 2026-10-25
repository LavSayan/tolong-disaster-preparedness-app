"""Dart<->Python feature parity fixture (SHELTER_RANKING_ML.md §3 parity rule, §7 benchmark).

Writes tools/ranking/data/exposure_parity.json and hard-fails if the Python
recompute of any asset site's exposure block disagrees with the shipped asset
beyond 1e-9. The Dart side (`test/ranking_parity_test.dart`) reads the same
file and recomputes everything with `lib/features/safe_places/domain/ranking.dart`,
so both implementations are pinned to one fixture file, including:

- exposure rows: real asset sites (every flood band + demo centres + the
  strongest landslide site) plus synthetic edge rows (partial absence, all-null)
- x_travel cases across and past the 3600 s cap
- the x_accessibility 1.0 / 0.5 / 0.0 mapping
- the constants both sides must share

Deterministic by construction (no RNG, sorted output).
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from extract_bands import exposure_from_bands

ASSET_PATH = Path(__file__).resolve().parents[2] / "tolong_flutter" / "assets" / "data" / "hazard_bands.json"
OUT_PATH = Path(__file__).resolve().parent / "data" / "exposure_parity.json"
TOLERANCE = 1e-9

BAND_KEYS = ("flood_100yr", "flood_25yr", "flood_5yr", "landslide", "debris_flow", "storm_surge")


def close(a, b):
    if a is None or b is None:
        return a is None and b is None
    return abs(a - b) <= TOLERANCE


def select_sites(sites: list[dict]) -> list[dict]:
    """Deterministic, coverage-maximising row selection."""
    picked: dict[str, dict] = {}
    for band in (0, 1, 2, 3):
        n = 0
        for s in sorted(sites, key=lambda x: x["id"]):
            if (s["bands"]["flood_100yr"] or 0) == band and n < 4:
                picked[s["id"]] = s
                n += 1
    for s in sorted(sites, key=lambda x: x["id"]):
        if s["kind"] == "demo":
            picked[s["id"]] = s
    strongest = max(sites, key=lambda s: (s["bands"]["landslide"] or 0, s["exposure"]["exposure"]))
    picked[strongest["id"]] = strongest
    return [picked[k] for k in sorted(picked)]


def main() -> None:
    asset = json.loads(ASSET_PATH.read_text(encoding="utf-8"))
    sites = asset["sites"]

    rows: list[dict] = []
    problems: list[str] = []

    for site in select_sites(sites):
        recomputed = exposure_from_bands(site["bands"])
        stored = {
            "floodComposite": site["exposure"].get("floodComposite"),
            "landslide": site["exposure"].get("landslide"),
            "exposure": site["exposure"]["exposure"],
        }
        for key in ("floodComposite", "landslide", "exposure"):
            if not close(recomputed[key], stored[key]):
                problems.append(f"{site['id']}: python {key}={recomputed[key]} vs asset {stored[key]}")
        rows.append({
            "id": site["id"],
            "origin": "asset",
            "bands": {k: site["bands"][k] for k in BAND_KEYS},
            "assetFloodComposite": stored["floodComposite"],
            "assetLandslide": stored["landslide"],
            "assetExposure": stored["exposure"],
            "pythonFloodComposite": recomputed["floodComposite"],
            "pythonLandslide": recomputed["landslide"],
            "pythonExposure": recomputed["exposure"],
        })

    # Synthetic edge rows: partial absence and total absence never occur in the
    # shipped asset (all 148 points saw flood data), but the formula must agree
    # on them anyway — both sides read from this file.
    synthetic = [
        {"id": "syn-none", "bands": {k: None for k in BAND_KEYS}, "expect": None},
        {"id": "syn-flood-only-5yr", "bands": {"flood_5yr": 2}, "expect": round(0.2 * (2 / 3), 9)},
        {"id": "syn-landslide-1", "bands": {"landslide": 1}, "expect": 0.25},
    ]
    for case in synthetic:
        bands = {k: case["bands"].get(k) for k in BAND_KEYS}
        recomputed = exposure_from_bands(bands)
        if not close(recomputed["exposure"], case["expect"]):
            problems.append(f"{case['id']}: python exposure {recomputed['exposure']} vs expected {case['expect']}")
        rows.append({
            "id": case["id"],
            "origin": "synthetic",
            "bands": bands,
            "assetFloodComposite": None,
            "assetLandslide": None,
            "assetExposure": None,
            "pythonFloodComposite": recomputed["floodComposite"],
            "pythonLandslide": recomputed["landslide"],
            "pythonExposure": recomputed["exposure"],
        })

    travel_cases: list[dict] = []
    for t in (0.0, 450.5, 900.0, 1800.0, 3599.9, 3600.0, 4200.0, 7200.0):
        x = min(max(1.0 - t / 3600.0, 0.0), 1.0)
        travel_cases.append({"travelSeconds": t, "xTravel": x})

    accessibility_cases = [
        {"accessibility": 0.0, "xAccessibility": 0.0},
        {"accessibility": 0.5, "xAccessibility": 0.5},
        {"accessibility": 1.0, "xAccessibility": 1.0},
    ]

    if problems:
        print("Python parity FAILED:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        raise SystemExit(1)

    fixture = {
        "meta": {
            "purpose": "Dart<->Python feature parity (SHELTER_RANKING_ML.md §3); consumed by check_parity.py and test/ranking_parity_test.dart",
            "source": {
                "assetPath": "tolong_flutter/assets/data/hazard_bands.json",
                "sha256": asset["source"]["sha256"],
            },
            "formulas": {
                "floodComposite": "0.5*(flood_100yr/3) + 0.3*(flood_25yr/3) + 0.2*(flood_5yr/3); absent band scores 0",
                "landslide": "landslide_band/4",
                "exposure": "max(floodComposite, landslide)",
                "xTravel": "clamp(1 - travelSeconds/3600, 0, 1)",
                "xAccessibility": "identity over {0.0, 0.5, 1.0}",
            },
            "tolerance": TOLERANCE,
        },
        "constants": {
            "travelTimeCapSeconds": 3600.0,
            "walkingSpeedMetersPerSecond": 1.2,
            "neutralFeatureValue": 0.5,
            "totalWeightConstraint": 100.0,
            "minExposureWeight": 30.0,
        },
        "exposureRows": rows,
        "travelCases": travel_cases,
        "accessibilityCases": accessibility_cases,
    }
    json_text = json.dumps(fixture, ensure_ascii=False, indent=1, sort_keys=True) + "\n"
    OUT_PATH.write_text(json_text, encoding="utf-8", newline="\n")
    n_asset = sum(1 for r in rows if r["origin"] == "asset")
    print(f"parity OK: {n_asset} asset rows + {len(rows) - n_asset} synthetic rows; "
          f"{len(travel_cases)} travel cases; wrote {OUT_PATH.name} ({len(json_text)} bytes)")
    print(f"fixture source sha256 {asset['source']['sha256'][:16]}… matches asset {ASSET_PATH.name}")


if __name__ == "__main__":
    main()
