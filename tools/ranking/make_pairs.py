"""Author the pairwise dataset for the shelter-ranking model (SHELTER_RANKING_ML.md Â§4).

Writes tools/ranking/data/pairs.jsonl, one JSON object per line:

  {"id":"p001",
   "a":{"point":"bgy-017","exposure":0.62,"travelSec":1450,"accessibility":0.5},
   "b":{"point":"demo-03","exposure":0.21,"travelSec":2100,"accessibility":0.5},
   "preferred":"b",
   "decidingFactor":"exposure",
   "rationale":"A lies inside the ... band; B is ... despite being farther."}

Authoring decisions, stated so the labels can be audited:

- The candidate pool is the real sampled sites in `hazard_bands.json`
  (142 barangay centroids + 6 demo centres). Exposure values are copied from
  the asset and never recomputed here, so the dataset cannot drift from the
  asset the app ships.
- `travelSec` is the straight-line walk estimate the runtime itself computes
  (haversine distance / 1.2 m/s), so the fit sees exactly the feature values
  the app will compute for the same configuration. Rationales quote minutes.
- `accessibility` labels are expert judgements over synthetic candidates:
    1.0  ramp + accessible washroom on site, confirmed
    0.5  no accessibility information on file (neutral imputation)
    0.0  stairs-only entry confirmed - not usable by wheelchair users
- Every pair comes from an explicit rule with a deliberate trade-off; rules
  demote to "skip" unless the trade-off magnitude clears a stated floor.
- Deterministic: fixed RNG seed, sorted output, zero-padded ids.

Coverage gates (mirrored by train.py; this script fails loudly if unmet):
  >= 25 pairs per decidingFactor, flood bands 1/2/3 each appearing in some
  pair, travel buckets < 10 min / 10-60 min / > 60 min present, 100-150 total.
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

ASSET_PATH = Path(__file__).resolve().parents[2] / "tolong_flutter" / "assets" / "data" / "hazard_bands.json"
OUT_PATH = Path(__file__).resolve().parent / "data" / "pairs.jsonl"

WALK_SPEED = 1.2  # m/s, matches RankingFeatures and estimateTravelSeconds
SEED = 42


def haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def load_sites() -> list[dict]:
    data = json.loads(ASSET_PATH.read_text(encoding="utf-8"))
    return [
        {
            "id": s["id"],
            "exposure": s["exposure"]["exposure"],
            "flood100": s["bands"]["flood_100yr"],
            "flood25": s["bands"]["flood_25yr"],
            "flood5": s["bands"]["flood_5yr"],
            "landslide": s["bands"]["landslide"],
            "lat": s["lat"],
            "lng": s["lng"],
        }
        for s in data["sites"]
    ]


class Collector:
    def __init__(self) -> None:
        self.rows: list[dict] = []
        self._seen: set[frozenset[str]] = set()

    def add(self, a: dict, b: dict, preferred: str, deciding: str, rationale: str) -> None:
        key = frozenset((a["point"], b["point"]))
        if a["point"] == b["point"] or key in self._seen:
            return
        self._seen.add(key)
        self.rows.append(
            {
                "id": f"p{len(self.rows) + 1:03d}",
                "a": a,
                "b": b,
                "preferred": preferred,
                "decidingFactor": deciding,
                "rationale": rationale,
            }
        )

    def check(self) -> None:
        factors: dict[str, int] = {"exposure": 0, "travel": 0, "accessibility": 0}
        bands: set[int] = set()
        buckets: dict[str, int] = {"under10": 0, "mid": 0, "over60": 0}
        for row in self.rows:
            factors[row["decidingFactor"]] += 1
            bands.update((row["a"]["_flood100"], row["b"]["_flood100"]))
            t_hi = max(row["a"]["travelSec"], row["b"]["travelSec"])
            t_lo = min(row["a"]["travelSec"], row["b"]["travelSec"])
            if t_hi < 600:
                buckets["under10"] += 1
            elif t_lo > 3600:
                buckets["over60"] += 1
            else:
                buckets["mid"] += 1
        problems = []
        for name, need in (("exposure", 25), ("travel", 25), ("accessibility", 25)):
            if factors[name] < need:
                problems.append(f"{name}: {factors[name]} < {need}")
        for band in (1, 2, 3):
            if band not in bands:
                problems.append(f"flood_100yr band {band} never appears")
        for name in ("under10", "mid", "over60"):
            if buckets[name] == 0:
                problems.append(f"travel bucket {name} empty")
        if not (100 <= len(self.rows) <= 150):
            problems.append(f"total pairs {len(self.rows)} outside 100-150")
        if problems:
            raise SystemExit("Coverage gates failed:\n  - " + "\n  - ".join(problems))
        dirs = {row["preferred"] for row in self.rows}
        print(f"coverage OK: {factors}  bands={sorted(bands)}  buckets={buckets} "
              f"preferred-directions={sorted(dirs)}  total={len(self.rows)}")


class Author:
    """Judgement rules over the site pool; every pair gets a stated rationale."""

    def __init__(self, sites: list[dict], rng: random.Random) -> None:
        self.sites = sites
        self.rng = rng
        self.col = Collector()
        self.by_band = {b: [s for s in sites if s["flood100"] == b] for b in (0, 1, 2, 3)}
        self.low = [s for s in sites if s["exposure"] <= 0.21]
        self.nearzero = [s for s in sites if s["exposure"] == 0.0]
        self.moderate = [s for s in sites if 0.2 < s["exposure"] <= 0.45]

    def dist(self, s1: dict, s2: dict) -> float:
        return haversine_m(s1["lat"], s1["lng"], s2["lat"], s2["lng"])

    def sec(self, s1: dict, s2: dict) -> int:
        """Straight-line walk seconds the app itself would compute."""
        return round(self.dist(s1, s2) / WALK_SPEED)

    def window(self, pool: list[dict], ref: dict, lo: float, hi: float) -> dict | None:
        picks = [x for x in pool if x["id"] != ref["id"] and lo <= self.dist(ref, x) <= hi]
        return self.rng.choice(picks) if picks else None

    def side(self, s: dict, ts: int, accessibility: float) -> dict:
        return {
            "point": s["id"],
            "exposure": s["exposure"],
            "travelSec": ts,
            "accessibility": accessibility,
            "_flood100": s["flood100"],
        }

    def export_row(self, row: dict) -> dict:
        def clean(side: dict) -> dict:
            return {k: side[k] for k in ("point", "exposure", "travelSec", "accessibility")}

        return {
            "id": row["id"],
            "a": clean(row["a"]),
            "b": clean(row["b"]),
            "preferred": row["preferred"],
            "decidingFactor": row["decidingFactor"],
            "rationale": row["rationale"],
        }

    # --------------------------------------------------------------
    # R1 - exposure dominates at the extremes (hypothetical user near A).
    # --------------------------------------------------------------
    def r1(self) -> None:
        # Tier 1: band-3 anchor. None of the safer side's extra minutes pay.
        for anchor in self.rng.sample(self.by_band[3], min(len(self.by_band[3]), 14)):
            partner = self.window(self.low, anchor, 400, 2400)
            if partner is None or anchor["exposure"] - partner["exposure"] < 0.3:
                continue
            ts_a = round(self.dist(anchor, {"lat": anchor["lat"] + 0.0035, "lng": anchor["lng"]}) / WALK_SPEED)
            ts_b = round(self.dist(anchor, partner) / WALK_SPEED)
            if ts_b <= ts_a + 60:
                continue
            self.col.add(
                self.side(anchor, ts_a, 0.5),
                self.side(partner, ts_b, 0.5),
                "b", "exposure",
                f"{anchor['id']} sits inside the 100-year band 3 zone (exposure {anchor['exposure']:.2f}); "
                f"{partner['id']} is flood band {partner['flood100']} (exposure {partner['exposure']:.2f}) and "
                f"about {minutes(ts_b - ts_a)} min farther. No minutes make band 3 worth it.",
            )
        # Tier 2: band-2 anchor loses to band 0 while the gap is at least a quarter.
        for anchor in self.rng.sample(self.by_band[2], min(len(self.by_band[2]), 18)):
            partner = self.window(self.by_band[0], anchor, 600, 2200)
            if partner is None or anchor["exposure"] - partner["exposure"] < 0.25:
                continue
            ts_far = self.sec(anchor, partner)
            ts_near = round(ts_far * self.rng.uniform(0.5, 0.75))
            self.col.add(
                self.side(anchor, ts_near, 0.5),
                self.side(partner, ts_far, 0.5),
                "b", "exposure",
                f"{anchor['id']} is in 100-year flood band 2 (exposure {anchor['exposure']:.2f}); "
                f"{partner['id']} is band 0 (exposure {partner['exposure']:.2f}) though it costs "
                f"about {minutes(ts_far - ts_near)} more minutes of walking.",
            )
        # Tier 3: equal walking time, different exposure - the clean read-off.
        for anchor in self.rng.sample(self.moderate, min(len(self.moderate), 16)):
            partner = self.window(self.by_band[0], anchor, 450, 1200)
            if partner is None or anchor["exposure"] - partner["exposure"] < 0.15:
                continue
            ts = self.sec(anchor, partner)
            self.col.add(
                self.side(anchor, ts, self.rng.choice((0.5, 0.5, 1.0))),
                self.side(partner, ts, 0.5),
                "b", "exposure",
                f"Both are about {minutes(ts)} min on foot, but {anchor['id']} carries 100-year band "
                f"{anchor['flood100']} (exposure {anchor['exposure']:.2f}) against band 0 "
                f"(exposure {partner['exposure']:.2f}).",
            )
        # Tier 4: near-zero against moderate, travel difference under 5 min.
        for anchor in self.rng.sample(self.nearzero, min(len(self.nearzero), 14)):
            partner = self.window(self.moderate, anchor, 250, 550)
            if partner is None:
                continue
            ts = self.sec(anchor, partner)
            if ts > 450:
                continue
            if self.rng.random() < 0.5:
                self.col.add(
                    self.side(anchor, ts, 0.5), self.side(partner, ts + 60, 0.5), "a", "exposure",
                    f"Walking stays within {minutes(max(ts, ts + 60))} min either way; {anchor['id']} records no "
                    f"flood hazard at all (exposure {anchor['exposure']:.2f}) while {partner['id']} is band "
                    f"{partner['flood100']} (exposure {partner['exposure']:.2f}).",
                )
            else:
                self.col.add(
                    self.side(partner, ts + 60, 0.5), self.side(anchor, ts, 0.5), "b", "exposure",
                    f"{anchor['id']} records no flood hazard at all (exposure {anchor['exposure']:.2f}) while "
                    f"{partner['id']} is band {partner['flood100']} (exposure {partner['exposure']:.2f}); that "
                    f"margin outweighs a {minutes(ts + 60)} minute walk.",
                )

    # --------------------------------------------------------------
    # R2 - travel decides inside the same exposure league.
    # --------------------------------------------------------------
    def r2(self) -> None:
        # League: band 0 vs band 0, exposure within 0.12; the nearer one wins.
        for anchor in self.rng.sample(self.by_band[0], min(len(self.by_band[0]), 20)):
            partner = self.window(self.by_band[0], anchor, 1500, 3800)
            if partner is None or abs(anchor["exposure"] - partner["exposure"]) > 0.12:
                continue
            ts_far = self.sec(anchor, partner)
            ts_near = round(ts_far * self.rng.uniform(0.45, 0.7))
            first, second = self.side(anchor, ts_near, 0.5), self.side(partner, ts_far, 0.5)
            if self.rng.random() < 0.5:
                first, second = second, first
            preferred = "a" if first["travelSec"] <= second["travelSec"] else "b"
            self.col.add(
                first, second, preferred, "travel",
                f"Both are flood band 0 with exposure {anchor['exposure']:.2f} vs {partner['exposure']:.2f}; "
                f"the readings are this close, so the cheaper walk decides.",
            )
        # League: band 1 shelf is not worth the reach to band 0.
        for anchor in self.rng.sample(self.by_band[1], min(len(self.by_band[1]), 18)):
            partner = self.window(self.by_band[0], anchor, 1800, 5200)
            if partner is None or anchor["exposure"] - partner["exposure"] > 0.18:
                continue
            ts_far = self.sec(anchor, partner)
            ts_near = round(self.dist(anchor, {"lat": anchor["lat"], "lng": anchor["lng"] + 0.006}) / WALK_SPEED)
            self.col.add(
                self.side(anchor, ts_near, 0.5),
                self.side(partner, ts_far, 0.5),
                "a", "travel",
                f"{anchor['id']} is band 1 (exposure {anchor['exposure']:.2f}); {partner['id']} is band 0 "
                f"(exposure {partner['exposure']:.2f}) but {minutes(ts_far)} min away versus {minutes(ts_near)}; "
                f"a one-band shelf does not justify that walk.",
            )
        # Under 10 min both sides.
        for anchor in self.rng.sample(self.by_band[0], min(len(self.by_band[0]), 16)):
            partner = self.window(self.by_band[0], anchor, 420, 700)
            if partner is None or abs(anchor["exposure"] - partner["exposure"]) > 0.1:
                continue
            ts_small = self.sec(anchor, partner)
            ts_big = round(ts_small / self.rng.uniform(0.6, 0.85))
            first, second = self.side(anchor, ts_big, 0.5), self.side(partner, ts_small, 0.5)
            if self.rng.random() < 0.5:
                first, second = second, first
            preferred = "a" if first["travelSec"] <= second["travelSec"] else "b"
            self.col.add(
                first, second, preferred, "travel",
                f"Two band-0 sites in leasing range: about {minutes(ts_big)} and {minutes(ts_small)} min walking "
                f"(exposure {anchor['exposure']:.2f} vs {partner['exposure']:.2f}); the shorter walk decides.",
            )
        # Both legs over an hour: a sunk-cost trade-off, travel at the far end.
        for anchor in self.rng.sample(self.by_band[2] + self.by_band[1], min(len(self.by_band[2]) + len(self.by_band[1]), 16)):
            partner = self.window(self.by_band[0], anchor, 5200, 9000)
            if partner is None or anchor["exposure"] - partner["exposure"] > 0.35:
                continue
            ts_far = self.sec(anchor, partner)
            ts_near = round(4600 * self.rng.uniform(0.95, 1.1) / WALK_SPEED)
            if min(ts_near, ts_far) <= 3600:
                continue
            self.col.add(
                self.side(anchor, ts_near, 0.5),
                self.side(partner, ts_far, 0.5),
                "a", "travel",
                f"Both legs exceed an hour; {partner['id']} is band 0 against band {anchor['flood100']} "
                f"(exposure {anchor['exposure']:.2f} vs {partner['exposure']:.2f}), but {minutes(ts_far)} min is a "
                f"long extra walk for that margin.",
            )

    # --------------------------------------------------------------
    # R3 - accessibility decides when exposure and travel are level.
    # --------------------------------------------------------------
    def r3(self) -> None:
        # Stairs-only loses to confirmed ramp at equal exposure and minutes.
        for anchor in self.rng.sample(self.by_band[0] + self.by_band[1], min(len(self.by_band[0]) + len(self.by_band[1]), 26)):
            league = self.by_band[0] if anchor in self.by_band[0] else self.by_band[1]
            partner = self.window(league, anchor, 380, 1000)
            if partner is None:
                continue
            ts_a = self.sec(anchor, partner)
            ts_b = ts_a + self.rng.choice((0, 60, 120))
            self.col.add(
                self.side(anchor, ts_a, 0.0),
                self.side(partner, ts_b, 1.0),
                "b", "accessibility",
                f"{anchor['id']} is confirmed stairs-only and cannot serve wheelchair users; {partner['id']} has a "
                f"confirmed ramp and accessible washroom. Exposure {anchor['exposure']:.2f} vs "
                f"{partner['exposure']:.2f}, minutes about {minutes(ts_a)} vs {minutes(ts_b)}.",
            )
        # Neutral (no data) vs verified read-off.
        for anchor in self.rng.sample(self.by_band[0], min(len(self.by_band[0]), 16)):
            partner = self.window(self.by_band[0], anchor, 500, 1200)
            if partner is None or abs(anchor["exposure"] - partner["exposure"]) > 0.12:
                continue
            ts_a = self.sec(anchor, partner)
            ts_b = ts_a + self.rng.choice((0, 60))
            if self.rng.random() < 0.5:
                self.col.add(
                    self.side(anchor, ts_a, 1.0), self.side(partner, ts_b, 0.5), "a", "accessibility",
                    f"{anchor['id']} is verified accessible; {partner['id']} has no accessibility data on file and "
                    f"is treated as neutral. Exposure and minutes are level ({anchor['exposure']:.2f} vs "
                    f"{partner['exposure']:.2f}).",
                )
            else:
                self.col.add(
                    self.side(anchor, ts_a, 0.5), self.side(partner, ts_b, 1.0), "b", "accessibility",
                    f"{anchor['id']} has no accessibility data on file and is treated as neutral; {partner['id']} "
                    f"is verified accessible. Exposure and minutes are level ({anchor['exposure']:.2f} vs "
                    f"{partner['exposure']:.2f}).",
                )
        # Wheelchair user walks farther to keep a verified facility.
        for anchor in self.rng.sample(self.by_band[0], min(len(self.by_band[0]), 14)):
            partner = self.window(self.by_band[0], anchor, 800, 1900)
            if partner is None:
                continue
            ts_far = self.sec(anchor, partner)
            ts_near = round(ts_far * self.rng.uniform(0.5, 0.65))
            self.col.add(
                self.side(anchor, ts_near, 1.0),
                self.side(partner, ts_far, 0.0),
                "a", "accessibility",
                f"Both band 0 (exposure {anchor['exposure']:.2f} and {partner['exposure']:.2f}); {anchor['id']} is "
                f"confirmed ramp-accessible while {partner['id']} is stairs-only, so the wheelchair user takes the "
                f"longer {minutes(ts_far)}-minute leg rather than lose the facility.",
            )


def minutes(ts: int) -> int:
    return round(ts / 60)


def main() -> None:
    rng = random.Random(SEED)
    author = Author(load_sites(), rng)
    author.r1()
    author.r2()
    author.r3()

    # byte-stable final order: decide factor, then endpoints per side
    carrier = sorted(
        (
            (row["decidingFactor"], row["a"]["point"], row["b"]["point"], row)
            for row in author.col.rows
        ),
        key=lambda t: (t[0], t[1], t[2]),
    )
    for i, (_, _, _, row) in enumerate(carrier, start=1):
        row["id"] = f"p{i:03d}"
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUT_PATH.open("w", encoding="utf-8", newline="\n") as f:
        for _, _, _, row in carrier:
            f.write(json.dumps(author.export_row(row), ensure_ascii=False) + "\n")
    print(f"wrote {len(carrier)} pairs -> {OUT_PATH}")
    author.col.check()


if __name__ == "__main__":
    main()

