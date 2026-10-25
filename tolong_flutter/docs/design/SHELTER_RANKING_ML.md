# Phase 6 — Shelter ranking: the machine learning portion

Written 2026-10-19. Companion to `MAP_OPTIONS.md`: §4a explains the NOAH hazard data this model
reads, §4b the future A\* routing; this document specifies the shelter-recommendation model —
task, features, dataset, training, export, evaluation and its honesty constraints.

## 1. Scope and status

| Item | Status |
|---|---|
| Scoring engine (Dart, hand-set default weights) | **Done 2026-10-25** — `features/safe_places/domain/ranking.dart`, integrated in Safe Places |
| Feature parity fixture (Dart ≡ Python) | **Done** — `tools/ranking/check_parity.py` + `exposure_parity.json`, exact to 1e-9 |
| Pairwise dataset (hand-authored labels) | **Done** — `tools/ranking/data/pairs.jsonl`, 119 pairs, gates green |
| Trained weights (`assets/data/ranking_weights.json`) | **Done** — 30 / 58.1894 / 11.8106 (CV ties the baseline; provenance in the file) |
| Evaluation report (§7 tables) | **Done** — results pasted at the end of §7 (run 2026-10-25) |

**Phase order:** the engine works end to end on built-in default weights (45 / 35 / 20) before
any training happens. Training is Phase 3b: the app never blocks on the model, and an app without
`ranking_weights.json` behaves exactly like the pre-ML version.

## 2. Task definition

Pairwise ranking of evacuation centres, one decision per labelled pair:

```
P(A ≻ B) = σ( Σ_f w_f · (x_f(A) − x_f(B)) )        σ = logistic sigmoid
```

At inference the same weights give one score per candidate:

```
S(c) = Σ_f w_f · x_f(c)          Σ_f w_f = 100, x ∈ [0,1]  ⇒  S ∈ [0,100]
```

Higher is a better match for the user's situation. It is **not** a safety score: `S` mixes
modelled exposure, travel effort and accessibility, and says nothing about live conditions
(§8). No intercept is fitted — a global bias would have no physical meaning.

## 3. Features (exact — Dart and Python must agree)

### `x_exposure = 1 − exposure`

- Sampling rule: centre point + 4 points at 50 m (N/E/S/W); per source layer take the **max band**
  across samples (the centre's surroundings are at most as good as their worst sample).
- Flood composite per group, static constants: `0.5·(L100/3) + 0.3·(L25/3) + 0.2·(L5/3)`
  (`L*` = flood band level 1–3 for that return period).
- Landslide: `L/4` (`HAZ` code 1–4).
- `exposure = max(floodComposite, landslide) ∈ [0,1]`.
- Groups with **no QC data** (storm surge; earthquake and fire are not modelled by NOAH at all)
  are excluded from the feature entirely and reported once as a global note — **missing data is
  never a per-candidate bonus**. If the hazard asset itself fails to load, ranking is unavailable
  and the app falls back to the plain distance list.

### `x_travel = clamp(1 − t/3600, 0, 1)`

`t` = travel time in seconds: real route duration when fetched, otherwise straight-line distance
÷ **1.2 m/s** and labelled *estimated*. `T_max = 3600 s` (≈5 km on foot) is a **fixed** constant.

> **Change from the earlier draft:** the first draft normalized travel against the *current
> candidate set* (`1 − t/max_t`). Pairwise training needs features that depend only on the
> candidate, not on who else happens to be in the list, so the trained model uses this absolute
> form. Side benefit: scores become comparable across sessions instead of shifting with the
> candidate set. Anything past an hour on foot floors to 0 — in QC that pair is then separated by
> exposure alone, which is the correct behaviour for a walking evacuation choice.

### `x_accessibility` — 1.0 / 0.5 / 0.0

Only when the user's profile is **wheelchair**: ORS `wheelchair` route succeeded → 1.0,
failed → 0.0, not checked (only the top-3 candidates get fetched) → **0.5 neutral + an explicit
gap in the UI**. In walking mode the factor is excluded globally and the remaining weights
renormalize (45/35 → 56.25/43.75).

### Structural rules (all test-enforced)

- **Factor exclusion is all-or-nothing per invocation**; per-candidate unknowns use neutral 0.5
  + a gap. Per-candidate renormalization is forbidden — it would break comparability between
  candidates.
- **Safety monotonicity:** with `w ≥ 0` and monotone features, a candidate with strictly lower
  exposure *and* strictly lower travel time can never rank below another. This is the model's
  core correctness invariant, checked as a property test (≥1000 seeded pairs, zero violations)
  against **both** the trained and the default weights.

### Parity rule

Python re-implements §3 from the same `hazard_bands.json` the app ships. The fixture
`tools/ranking/data/exposure_parity.json` (sample points + expected values) is asserted by a Dart
test and a Python check to 1e-9. Without this, train/serve skew is invisible.

## 4. The dataset

**What it is:** ~100–150 hand-authored pairwise preference judgements over synthetic shelter
candidates. **What it is not:** user data (the app collects none) or outcome data (nobody in QC has
published "households that reached shelter X" records). It is expert-labelled — stated plainly in
§8 and §10.

### File and schema

`tools/ranking/data/pairs.jsonl`, one JSON object per line:

```json
{"id":"p001",
 "a":{"point":"bgy-017","exposure":0.62,"travelSec":1450,"accessibility":0.5},
 "b":{"point":"demo-03","exposure":0.21,"travelSec":2100,"accessibility":0.5},
 "preferred":"b",
 "decidingFactor":"exposure",
 "rationale":"A lies inside the 100-year band III zone; B is 5-year band I despite being farther."}
```

`decidingFactor` and `rationale` are required: the first for stratified folds and coverage
checks, the second as ground truth for the explanation audit (§7). Feature values are computed
once and stored on the pair so the fit never silently drifts from a recompute.

### Candidate pool

The 142 barangay centroids (`assets/data/qc_barangays.json`) + seeded jitter + the 6 demo centres.
Pairs are chosen to be **non-trivial**: deliberate trade-offs (nearer but far more exposed),
otherwise every label is obvious and the fit is meaningless.

### Coverage requirements (enforced by `tools/ranking/train.py`, fails the fit if unmet)

| Requirement | Minimum |
|---|---|
| Pairs whose `decidingFactor` is exposure / travel / accessibility | ≥ 25 each |
| Flood bands 1, 2 and 3 each appear in some pair's exposure | all three |
| Travel spread: some pairs with both < 10 min, some 10–60 min, some > 60 min | present |
| Total pairs | 100–150 |

If the accessibility minimum cannot be met (checking wheelchair feasibility needs ORS during
authoring), **v1 ships as a two-factor model** (exposure + travel, renormalized) — a documented
fallback, not a silent one.

### Splits

5-fold cross-validation, `KFold(n_splits=5, shuffle=True, random_state=42)` — the set is too
small for a single hold-out. Stratification by `decidingFactor`.

## 5. Training

- **Model:** L2-regularized logistic regression on `Δx` (Bradley–Terry), no intercept.
- **Solver:** `scipy.optimize.minimize(method="SLSQP")` with:
  - equality constraint `Σ w = 100`
  - bounds `w_exposure ∈ [30,100]`, `w_travel, w_accessibility ∈ [0,100]`
- **Constraints are safety requirements, not tuning knobs.** `w ≥ 0` is what preserves the
  monotonicity invariant; the exposure floor of 30 guarantees the model can never become a
  "distance-only" ranker no matter what the small dataset suggests.
- **Regularization:** `λ ∈ {0, 0.01, 0.1, 1}` chosen by CV log loss; chosen value reported.
- **Metrics:** CV pairwise accuracy + log loss, always reported **against the hand-set baseline
  45/35/20** evaluated on the same folds. If the trained model does not beat the baseline, the
  baseline ships and the report says so — that result is as defensible as a win.
- **Environment:** Python ≥ 3.11, `numpy`, `scipy`, `scikit-learn` (folds/metrics only), pinned in
  `tools/ranking/requirements.txt`. No PyTorch — this is a linear model over three features.
- **Determinism:** fixed seeds, sorted output, 4-decimal rounding → re-running the fit on the same
  `pairs.jsonl` yields byte-identical weights.

## 6. Export and on-device integration

### `tools/ranking/train.py` writes `tolong_flutter/assets/data/ranking_weights.json`

```json
{ "version": 1,
  "method": "pairwise-logistic-slsqp",
  "factors": ["exposure", "travel", "accessibility"],
  "weights": {"exposure": 45.0, "travel": 35.0, "accessibility": 20.0},
  "constraints": {"sum": 100, "nonNegative": true, "minExposure": 30},
  "dataset": {"path": "tools/ranking/data/pairs.jsonl", "sha256": "…", "pairs": 142},
  "fit": {"cvPairwiseAccuracy": 0.0, "cvLogLoss": 0.0, "baselineAccuracy": 0.0, "lambda": 0.1},
  "fittedAt": "2026-10-19" }
```

The file is small (<1 KB) — covered by the existing `assets/data/` pubspec entry.

### In the app

- `RankingWeights` value type in `lib/features/safe_places/domain/` with
  `RankingWeights.defaults` = the hand-set 45/35/20 (today's `static const`).
- `data/ranking_weights_repository.dart` loads the asset; **any failure — missing, corrupt,
  version mismatch, constraint violation → `defaults`**, never a crash and never a partial model.
- The centre card shows which weights are active (trained v1 vs default) so provenance is visible
  rather than assumed.
- Tests assert the constraint set (sum = 100, all ≥ 0, exposure ≥ 30) on **both** the defaults
  and the shipped asset, and the monotonicity property test runs against both.

## 7. Evaluation plan (both kinds, results to be pasted here)

Produced by `test/evaluation/ranking_evaluation_test.dart` (runs under
`flutter test --concurrency=1`, prints markdown tables):

**Ablation + explainability**

| Report | Method |
|---|---|
| Kendall's τ per ablated factor vs full ranking | drop one factor, re-rank all fixture sets |
| Monotonicity violations per ablation | property test, must be 0 for any non-negative weights |
| Trained vs hand-set accuracy | 5-fold CV table from `train.py` |
| Explanation audit | every displayed reason ↔ a non-zero contribution; every gap ↔ actually missing data |
| Forbidden-claims scan | the `hazard_layer_test.dart` list (`is safe`, `safe route`, `guaranteed safe`, `will not flood`) applied to every generated reason string |

**Benchmarks**

| Metric | Target |
|---|---|
| `hazard_bands.json` size (Phase 1 gate) | ≤ 5 MB |
| Cold parse (in an `Isolate`) | reported ms |
| `exposureAt` × 10 000 points | reported ms |
| Full ranking, N=6 and N=1000 | reported ms |
| ORS calls per re-rank | ≤ 3 (asserted) |
| Parity fixture Dart ≡ Python | exact, to 1e-9 |

### Results (run 2026-10-25, `flutter test --concurrency=1`, analyze clean, 243 tests total)

**Golden orderings** — `test/fixtures/ranking_golden.json`, 12 sets; both weight sets reproduce
every ordering, the weakest chain margin at the two sets' per-factor minima is quoted per set:

| set | baseline ok | trained ok | weakest margin |
|---|---|---|---|
| band3 vs band0, same walk | yes | yes | 22.50 |
| safer wins even at 10 more minutes | yes | yes | 6.17 |
| inside the league, the shorter walk wins | yes | yes | 3.71 |
| verified access beats failed access at level features | yes | yes | 10.31 |
| verified beats neutral gap | yes | yes | 5.91 |
| marginally closer verified facility wins | yes | yes | 6.00 |
| past the travel cap only exposure is signed | yes | yes | 12.90 |
| equal travel and access: floor separates | yes | yes | 7.50 |
| half the travel time wins inside band 0 | yes | yes | 17.50 |
| verified access worth 10 extra minutes | yes | yes | 5.98 |
| worst corner loses to anything moderate | yes | yes | 22.41 |
| ten per cent exposure edge at everything else level | yes | yes | 0.90 |

**Kendall's τ, full ranking vs one-factor ablations** (148-site asset universe, synthetic
travel/accessibility on fixed seeds; caution for reading it: this universe's travel draw is
built from the sites' latitude, so it correlates with exposure — the τ=1.00 travel row shows
that construction, not a model property):

| drop | baseline τ | trained τ |
|---|---|---|
| exposure | 0.4322 | 0.4225 |
| travel | 1.0000 | 1.0000 |
| accessibility | 0.6797 | 0.6895 |

**Monotonicity under ablations** — violations 0/200 per ablation (exposure / travel /
accessibility), sampled across non-negative weight space with the ablated factor at 0.

**Trained vs hand-set** (5-fold CV, StratifiedKFold shuffle, seed 42, 119 pairs):

| metric | trained v1 | hand-set baseline |
|---|---|---|
| cvPairwiseAccuracy | 0.9250 | 0.9250 |
| chosen lambda | 0.0 | n/a |

The trained fit ties the baseline: shipped weights are 30.0 / 58.1894 / 11.8106 with the tie in
the shipped `fit` record. The disagreements inside these folds are the deliberate trade-offs the
league rules contain (§4 labels); the report says "tie", not a win. A tie still ships full
trained provenance because the fold numbers and dataset sha sit in the asset.

**Explanation audit** — contributions decompose exactly (sum == score to 1e-9) for all 12 golden
sets under both weight sets; zero-weight factors never appear as a reason.

**Forbidden-claims scan** — 36 ranking strings across `app_en.arb` + `app_fil.arb`, 0
occurrences of any forbidden phrase.

**Benchmarks** (this run, dev laptop):

| metric | value |
|---|---|
| `hazard_bands.json` size | 82 240 bytes (gate ≤ 5 MB) |
| cold parse in an isolate | ~14 ms |
| `exposureAt` × 10 000 points | ~93 ms (9.4 µs/point) |
| full ranking, N=6 | ~175 µs |
| full ranking, N=1000 | ~1.4 ms |
| ORS calls per re-rank (engine run) | 0 (straight-line estimates; a route request happens only for the SELECTED centre, ≤ 1 per re-rank — budget ≤ 3 holds) |
| parity fixture Dart ≡ Python | `exposure_parity.json`: exact to 1e-9, sha pinned |

**Golden cases:** `test/fixtures/ranking_golden.json` — ~12 hand-authored candidate sets with
expected orderings and rationale; both weight sets must satisfy them.

## 8. Safety and honesty constraints

- **Structural guarantees:** non-negative weights + exposure floor ⇒ monotonicity holds by
  construction, not by hope. A future retrain cannot silently learn "avoid the exposed shelter if
  it is farther".
- **Wording:** the model outputs *rankings and contributions*, never the word "safe". Forbidden
  claims are enforced against every generated string. Required disclosures stay: modelled
  scenarios, not live conditions; not a safety guarantee; NOAH models no earthquake and no fire.
- **Data honesty:** labels are expert-authored over synthetic candidates — disclosed here and in
  the evaluation report. Checked-not-verified accessibility shows as a gap, never as a pass.
- **Licence:** the NOAH archive this model's features come from is **not cleared for
  distribution** (`MAP_OPTIONS.md` §4a/§5) — ask UP Resilience Institute before any public release.
  Training/evaluation on it is fine; shipping the feature asset is not, until then.

## 9. How to re-run

```bash
# one-time environment
python -m venv tools/ranking/.venv
tools/ranking/.venv/Scripts/activate        # bin/activate on macOS/Linux
pip install -r tools/ranking/requirements.txt

python tools/ranking/check_parity.py        # Dart↔Python feature parity fixture
python tools/ranking/train.py               # validates coverage, fits, prints CV report,
                                            # writes tolong_flutter/assets/data/ranking_weights.json

cd tolong_flutter
flutter analyze                             # must be clean
flutter test --concurrency=1                # 195 existing + ranking, parity, evaluation tests
```

## 10. Limitations and next steps

**Limitations (stated, not hidden)**
- Small, single-author expert labels over synthetic candidates — the model learns *your* policy,
  which is the point, but it is not a population result.
- Neutral 0.5 imputation for unchecked accessibility can perturb order below the top-3.
- Fixed `T_max` assumption; a route slower than 1.2 m/s (wheelchair, crowds) is underestimated.
- No outcome data exists anywhere to validate against yet.

**Next steps, in order**
1. QC DRRMO centre list (email in `MAP_OPTIONS.md` §5) → real capacity/accessibility/status as
   additional features, replacing imputation with data.
2. A\* travel features (`MAP_OPTIONS.md` §4b) replace the 1.2 m/s estimate with actual walking
   time — a feature swap, not a model change.
3. If real usage ever produces selection logs: behavioural labels → hold-out evaluation against
   expert labels, and a learned-to-rank upgrade (LambdaMART-class) once the dataset is far larger
   than a linear model needs.
