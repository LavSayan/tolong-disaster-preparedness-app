# tools/ranking — shelter-ranking pipeline

Companion data tools for `docs/design/SHELTER_RANKING_ML.md` (the ranking/ML design used by
`lib/features/safe_places/`). Each writer tool is **deterministic** — same inputs, byte-identical
output — and ships a `--check` mode that re-derives the file in memory and byte-compares it
against the committed copy, so CI (or a quick command) doubles as a drift guard.

## Layout / artifacts

| Tool | Consumes | Emits | Status |
| --- | --- | --- | --- |
| `extract_bands.py` | `tolong_flutter/datasets/qc_flood.pmtiles`, `assets/data/qc_barangays.json`, `assets/data/evacuation_centers_dev.json` | `tolong_flutter/assets/data/hazard_bands.json` | Phase 0 — done, stdlib-only |
| `seismic_context.py` | `tolong_flutter/datasets/phivolcs_datasets/{2016..2022}/*.csv`, `hazard_bands.json` (site list) | `tools/ranking/data/seismic_context.json` | Phase 0 — done, stdlib-only |
| `make_pairs.py` | `hazard_bands.json` | `data/pairs.jsonl` (119 expert-labelled pairs, coverage-gated) | Phase 3 — done |
| `check_parity.py` | `hazard_bands.json`, `extract_bands.py` (formula home) | `data/exposure_parity.json` | Phase 3 — done, stdlib-only |
| `train.py` | `pairs.jsonl`, `hazard_bands.json` | `tolong_flutter/assets/data/ranking_weights.json` | Phase 4 — done (`requirements.txt`) |

## Phase 0 tools

### `hazard_bands.json` (`extract_bands.py`)

```pwsh
python -u tools/ranking/extract_bands.py --extract   # rebuild (≈70 s: 169 PMTiles tiles decoded)
python -u tools/ranking/extract_bands.py --check     # drift guard (byte-exact re-derivation)
```

Decodes the PMTiles archive standalone (varint/directory/MVT-polygon parsing, no third-party
dependency) and samples, per site, the max severity band across 5 samples
(centre + compass at 50 m):

- `flood_100yr` / `flood_25yr` / `flood_5yr` → attr `Var` ∈ 1..3 (`Band 1`..`3`)
- `landslide` → attr `HAZ` ∈ 1..4 (`Band 4` → LBS 4); `debris_flow` informational
- each band-EVAL point is evaluated once at the **finest zoom whose tile contains it and
  ships that layer** — the archive is *national* NOAH data (not a QC clip, despite claims),
  and low-zoom simplified rings can swallow inland Quezon City, which is why zooms are never
  mixed. `band null` = no data near the site at any zoom; `band 0` = data exists, no polygon
  at the point.
- `storm_surge` is sampled **nowhere** and is always `null`: the SSA layers are
  national-resolution; their simplified low-zoom rings overlap inland QC, so any per-site
  value would be an artifact. Spec §3 excludes surge from the exposure feature. Recorded once
  in the asset's `notes` array.
- exposure = `max(floodComposite, landslide)` with
  `floodComposite = 0.5·(100yr)/3 + 0.3·(25yr)/3 + 0.2·(5yr)/3`; `debris_flow` is
  informational only (spec §3).

### `seismic_context.json` (`seismic_context.py`)

```pwsh
python -u tools/ranking/seismic_context.py --extract   # rebuild (single pass over 62k events)
python -u tools/ranking/seismic_context.py --check     # drift guard
```

Per-site haversine join (50 km radius) of 62,725 PHIVOLCS events (2016-2022): event counts,
M4+ events, max magnitude, magnitude-weighted sum, `seismicProximityIndex` (normalised to the
peak). **Context only — never a ranking factor**; see the `role` and `method.caveat` fields
inside the file before quoting these numbers anywhere.

## Face validity (2026-10 sample pass)

Flood bands concentrate in the SW river corridors (Tullahan / San Juan) and thin toward the
Novaliches hills in the NE — consistent with Quezon City's flood geography; landslide is sparse
(flat city) and debris-flow empty. Storm surge null throughout, as expected inland.

## Phase 3 — the dataset and parity

### `pairs.jsonl` (`make_pairs.py`)

```pwsh
python -u tools/ranking/make_pairs.py     # deterministic (Seed 42); coverage gates fail loudly
```

119 hand-authored pairs over the real asset site pool. Content discipline:

- the pairs come from the judgement rules in the script's docstrings — deliberate trade-offs (exposure
  beats travel at the extremes; travel decides inside a league; accessibility decides at level
  features), never a formula dump, so the fit learns policy rather than echoing the generator;
- `travelSec` values are the app's own straight-line estimate (haversine / 1.2 m/s) — the fit
  sees exactly what the runtime computes;
- coverage gates mirror spec §4 (`>= 25` per deciding factor, flood bands 1-3 present, travel
  buckets < 10 min / 10-60 min / > 60 min, 100-150 pairs total).

### `exposure_parity.json` (`check_parity.py`)

```pwsh
python -u tools/ranking/check_parity.py
```

Re-derives every selected asset site's exposure block from its bands via the extractor's own
formula and hard-fails on any disagreement beyond 1e-9, then writes the fixture both sides read:
22 real asset rows (all flood bands + demo centres + the strongest landslide site), 3 synthetic
edge rows (partial absence, all-null), `x_travel` cases across the 3600 s cap, and the five
shared constants. `test/ranking_parity_test.dart` recomputes everything with the Dart formula.

## Phase 4 — training (`train.py`)

```pwsh
python -m pip install -r tools/ranking/requirements.txt   # one-time: numpy, scipy, scikit-learn
python -u tools/ranking/train.py [--dry-run]
```

Re-validates the §4 coverage gates (including joining `points` back to the asset for the
band-coverage check), fits the Bradley–Terry logistic weights on Δx with SLSQP (equality
`Σw = 100`, bounds `[30,100]/[0,100]/[0,100]`, analytic gradient, start at the hand-set 45/35/20),
picks λ ∈ {0, 0.01, 0.1, 1} by 5-fold out-of-fold log loss
(`StratifiedKFold(shuffle=True, random_state=42)`), compares CV accuracy against the baseline on
the same folds, then writes `assets/data/ranking_weights.json` with dataset sha + fit record.
4-decimal weight rounding with an exact-sum repair step keeps the constraint set intact.
Determinism: re-running on unchanged inputs byte-reproduces the file (same-day `fittedAt`).

2026-10-25 run: chosen λ 0.0, CV accuracy 0.9250 — **ties** the hand-set baseline; shipped
weights 30.0 / 58.1894 / 11.8106 with the tie recorded in the fit fields.

## Dependencies

`tools/` stays stdlib-only Python except the training stack. `requirements.txt` pins
numpy / scipy / scikit-learn for Phase 3-4 (sklearn supplies KFold + metric functions only, no
sklearn models):

```pwsh
python -m pip install -r tools/ranking/requirements.txt
```
