"""Train the shelter-ranking weights (SHELTER_RANKING_ML.md §5-§6).

Reads tools/ranking/data/pairs.jsonl, validates the §4 coverage gates, fits a
L2-regularized logistic regression on Δx (Bradley-Terry) with
scipy.optimize.minimize(method="SLSQP"), picks the regularizer by 5-fold CV
log loss against the hand-set baseline, and writes
tolong_flutter/assets/data/ranking_weights.json.

Everything is deterministic: fixed seeds, StratifiedKFold(shuffle=True,
random_state=42), sorted output, 4-decimal weight rounding with an exact-sum
repair step. Re-running on an unchanged pairs.jsonl byte-reproduces the file
(barring the fittedAt date).

Constraints are safety requirements, never tuning knobs (§5): weights
non-negative, sum exactly 100, exposure floored at 30 — the monotonicity
invariant (more exposure can never help a candidate) holds by construction.
If the trained fit fails to beat the baseline's CV accuracy, the baseline
ships and the report says so.

Usage:
    python train.py [--dry-run]
"""

from __future__ import annotations

import hashlib
import json
import math
import sys
from datetime import date
from pathlib import Path

import numpy as np
from scipy.optimize import minimize
from sklearn.model_selection import StratifiedKFold

ROOT = Path(__file__).resolve().parents[2]
PAIRS_PATH = Path(__file__).resolve().parent / "data" / "pairs.jsonl"
ASSET_PATH = ROOT / "tolong_flutter" / "assets" / "data" / "hazard_bands.json"
OUT_PATH = ROOT / "tolong_flutter" / "assets" / "data" / "ranking_weights.json"

LAMBDA_GRID = (0.0, 0.01, 0.1, 1.0)
N_FOLDS = 5
CV_SEED = 42
BASELINE = np.array([45.0, 35.0, 20.0])
FACTOR_ORDER = ("exposure", "travel", "accessibility")
BOUNDS_LOWER = (30.0, 0.0, 0.0)  # exposure floor is a safety requirement (§5)
DECIMALS = 4

TRAVEL_CAP = 3600.0


def x_exposure(exposure: float) -> float:
    return 1.0 - exposure


def x_travel(travel_sec: float) -> float:
    return min(max(1.0 - travel_sec / TRAVEL_CAP, 0.0), 1.0)


def load_pairs() -> list[dict]:
    rows = []
    for lineno, line in enumerate(PAIRS_PATH.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"pairs.jsonl line {lineno}: invalid JSON ({exc})")
        missing = [k for k in ("id", "a", "b", "preferred", "decidingFactor", "rationale") if k not in row]
        if missing:
            raise SystemExit(f"pairs.jsonl line {lineno}: missing {missing}")
        if row["preferred"] not in ("a", "b") or row["decidingFactor"] not in FACTOR_ORDER:
            raise SystemExit(f"pairs.jsonl line {lineno}: bad preferred/decidingFactor")
        for side in ("a", "b"):
            point = row[side]
            if not set(point) >= {"point", "exposure", "travelSec", "accessibility"}:
                raise SystemExit(f"pairs.jsonl line {lineno}: side {side} missing feature keys")
        rows.append(row)
    if len(rows) < 100 or len(rows) > 150:
        raise SystemExit(f"coverage gate: {len(rows)} pairs outside 100-150")
    return rows


def coverage_gate(rows: list[dict], band_by_point: dict[str, int | None]) -> None:
    factors = {f: 0 for f in FACTOR_ORDER}
    ids = band_by_point.keys()
    bands_seen: set[int] = set()
    buckets = {"under10": 0, "mid": 0, "over60": 0}
    for row in rows:
        factors[row["decidingFactor"]] += 1
        for side in (row["a"], row["b"]):
            pid = side["point"]
            if pid not in ids:
                raise SystemExit(f"{row['id']}: point {pid} is not in the hazard asset")
            band = band_by_point[pid]
            if band is not None:
                bands_seen.add(band)
        t_hi, t_lo = max(row["a"]["travelSec"], row["b"]["travelSec"]), min(row["a"]["travelSec"], row["b"]["travelSec"])
        if t_hi < 600:
            buckets["under10"] += 1
        elif t_lo > 3600:
            buckets["over60"] += 1
        else:
            buckets["mid"] += 1
    problems = [f"{name}: {count} < 25" for name, count in factors.items() if count < 25]
    problems += [f"flood_100yr band {b} never appears" for b in (1, 2, 3) if b not in bands_seen]
    problems += [f"travel bucket {b} empty" for b, n in buckets.items() if n == 0]
    if problems:
        raise SystemExit("coverage gates failed:\n  - " + "\n  - ".join(problems))
    print(f"coverage gates pass: {factors}  buckets={buckets}  bands={sorted(bands_seen)}")


def deltas(rows: list[dict]) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """X (n,3) of Δx = x_a − x_b in fixed factor order, y (+1 prefer a / −1 prefer b),
    fold labels. The margin y·(β·Δx) is then always β·(x_preferred − x_other)."""
    x, y, labels = [], [], []
    for row in rows:
        dx = (
            np.array([
                x_exposure(row["a"]["exposure"]),
                x_travel(row["a"]["travelSec"]),
                row["a"]["accessibility"],
            ])
            - np.array([
                x_exposure(row["b"]["exposure"]),
                x_travel(row["b"]["travelSec"]),
                row["b"]["accessibility"],
            ])
        )
        x.append(dx)
        y.append(1.0 if row["preferred"] == "a" else -1.0)
        labels.append(FACTOR_ORDER.index(row["decidingFactor"]))
    return np.array(x), np.array(y), np.array(labels)


def nll(beta: np.ndarray, x: np.ndarray, y: np.ndarray, lam: float) -> float:
    margin = y * (x @ beta)
    return float(np.mean(np.logaddexp(0.0, -margin)) + 0.5 * lam * np.dot(beta, beta))


def nll_grad(beta: np.ndarray, x: np.ndarray, y: np.ndarray, lam: float) -> np.ndarray:
    margin = y * (x @ beta)
    sigmoid_neg = 1.0 / (1.0 + np.exp(margin))
    return float(1.0 / len(y)) * (-(x * y[:, None]).T @ sigmoid_neg) + lam * beta


def fit_slsqp(x: np.ndarray, y: np.ndarray, lam: float) -> np.ndarray:
    constraints = ({"type": "eq", "fun": lambda beta: float(np.sum(beta) - 100.0),
                    "jac": lambda beta: np.ones(3)})
    result = minimize(
        nll, BASELINE.copy(), args=(x, y, lam), method="SLSQP",
        jac=nll_grad, bounds=list(zip(BOUNDS_LOWER, (100.0,) * 3)),
        constraints=constraints, options={"maxiter": 300, "ftol": 1e-12},
    )
    if not result.success:
        raise SystemExit(f"SLSQP failed (lambda={lam}): {result.message}")
    return result.x


def exact_sum(beta: np.ndarray) -> bool:
    return abs(float(np.sum(beta)) - 100.0) <= 1e-9


def round_weights(beta: np.ndarray) -> np.ndarray:
    """4-decimal rounding with an exact-sum repair step; keeps the constraint set."""
    rounded = np.round(beta, DECIMALS)
    residual = 100.0 - float(np.sum(rounded))
    # Residual |r| <= ~0.0005: repair on the largest weight never breaks bounds or floors.
    largest = int(np.argmax(rounded))
    repaired = rounded.copy()
    repaired[largest] = round(repaired[largest] + residual, DECIMALS)
    if not exact_sum(repaired) or repaired[0] < BOUNDS_LOWER[0] - 1e-9 or np.any(repaired < 0):
        raise SystemExit(f"weight repair violated constraints: {repaired}")
    return repaired


def evaluate(beta: np.ndarray, x: np.ndarray, y: np.ndarray) -> tuple[float, float]:
    """Accuracy and mean log loss of [beta] on [x]/[y]."""
    margins = y * (x @ beta)
    losses = np.logaddexp(0.0, -margins)
    hits = margins > 0
    return float(hits.mean()), float(losses.mean())


def saturated(beta: np.ndarray) -> bool:
    """The full safety constraint set of §5, evaluated on the rounded vector."""
    return (exact_sum(beta)
            and bool(np.all(beta >= 0))
            and bool(beta[0] >= BOUNDS_LOWER[0] - 1e-9))


def main() -> None:
    dry = "--dry-run" in sys.argv
    asset = json.loads(ASSET_PATH.read_text(encoding="utf-8"))
    band_by_point = {s["id"]: s["bands"]["flood_100yr"] for s in asset["sites"]}

    rows = load_pairs()
    coverage_gate(rows, band_by_point)
    x, y, fold_labels = deltas(rows)
    print(f"dataset: {len(rows)} pairs, sha256 {hashlib.sha256(PAIRS_PATH.read_bytes()).hexdigest()[:16]}…")

    # λ selection by out-of-fold log loss over the fixed folds (spec §5).
    folds = list(StratifiedKFold(n_splits=N_FOLDS, shuffle=True, random_state=CV_SEED).split(x, fold_labels))
    print(f"lambda grid {LAMBDA_GRID}, out-of-fold log loss per lambda:")
    chosen_lambda: float | None = None
    chosen_loss = math.inf
    for lam in LAMBDA_GRID:
        fold_losses = []
        for train_idx, test_idx in folds:
            beta = fit_slsqp(x[train_idx], y[train_idx], lam)
            fold_losses.append(evaluate(beta, x[test_idx], y[test_idx])[1])
        mean_loss = float(np.mean(fold_losses))
        print(f"  lambda {lam:<6}: mean out-of-fold logloss {mean_loss:.4f}")
        if mean_loss < chosen_loss:
            chosen_loss, chosen_lambda = mean_loss, lam
    lam = chosen_lambda
    assert lam is not None, "lambda grid is never empty"

    # Global fit + same-fold evaluation for trained vs baseline (§5 report table).
    beta_full = fit_slsqp(x, y, lam)
    trained_rows: list[dict] = []
    baseline_accuracy_list: list[float] = []
    for i, (train_idx, test_idx) in enumerate(folds, start=1):
        beta_fold = fit_slsqp(x[train_idx], y[train_idx], lam)
        tr_acc, tr_loss = evaluate(beta_fold, x[test_idx], y[test_idx])
        bl_acc, _ = evaluate(BASELINE, x[test_idx], y[test_idx])
        baseline_accuracy_list.append(bl_acc)
        trained_rows.append({
            "fold": i,
            "trainPairs": int(len(train_idx)),
            "cvPairwiseAccuracy": round(tr_acc, 4),
            "cvLogLoss": round(tr_loss, 4),
            "baselineAccuracy": round(bl_acc, 4),
        })
    mean_acc = float(np.mean([r["cvPairwiseAccuracy"] for r in trained_rows]))
    mean_loss = float(np.mean([r["cvLogLoss"] for r in trained_rows]))
    mean_baseline = float(np.mean(baseline_accuracy_list))

    weights, ships_baseline = (round_weights(BASELINE), True) if mean_acc < mean_baseline else (round_weights(beta_full), False)

    print()
    print("| fold | trainPairs | cvPairwiseAccuracy | cvLogLoss | baselineAccuracy |")
    print("|---|---|---|---|---|")
    for r in trained_rows:
        print(f"| {r['fold']} | {r['trainPairs']} | {r['cvPairwiseAccuracy']:.4f} | {r['cvLogLoss']:.4f} | "
              f"{r['baselineAccuracy']:.4f} |")
    if abs(mean_acc - mean_baseline) <= 1e-12:
        verdict = f"tie with the hand-set baseline ({mean_acc:.4f}); trained fit ships"
    elif mean_acc < mean_baseline:
        verdict = f"baseline ships (trained fit did not beat it: {mean_acc:.4f} < {mean_baseline:.4f})"
    else:
        verdict = f"trained fit ships (beats baseline {mean_baseline:.4f})"
    print(f"chosen lambda {lam}  mean accuracy {mean_acc:.4f}  mean logloss {mean_loss:.4f}  ->  {verdict}")

    if not saturated(weights):
        raise SystemExit("export: constraint precheck failed (sum/bounds/floor)")

    document = {
        "version": 1,
        "method": "pairwise-logistic-slsqp",
        "factors": list(FACTOR_ORDER),
        "weights": {name: float(weights[i]) for i, name in enumerate(FACTOR_ORDER)},
        "constraints": {"sum": 100, "nonNegative": True, "minExposure": 30},
        "dataset": {
            "path": "tools/ranking/data/pairs.jsonl",
            "sha256": hashlib.sha256(PAIRS_PATH.read_bytes()).hexdigest(),
            "pairs": len(rows),
        },
        "fit": {
            "cvPairwiseAccuracy": round(mean_acc, 4),
            "cvLogLoss": round(mean_loss, 4),
            "baselineAccuracy": round(mean_baseline, 4),
            "lambda": lam,
        },
        "fittedAt": date.today().isoformat(),
    }
    blob = json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    if dry:
        print("[dry-run] not written:")
        print(blob)
        return
    OUT_PATH.write_text(blob, encoding="utf-8", newline="\n")
    print(f"wrote {OUT_PATH} ({len(blob.encode())} bytes)")


if __name__ == "__main__":
    main()
