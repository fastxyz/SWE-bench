# scikit-learn__scikit-learn-13496

## Summary

**Severity:** Low — baseline silently shifts positional constructor arguments, but only
for the uncommon (and, in modern sklearn, discouraged) form of passing 6+ positional
constructor arguments.

Baseline and FVK both passed the official SWE-bench evaluation for *"Expose warm_start in
Isolation forest"*, but baseline inserted the new `warm_start` parameter in the **middle**
of `IsolationForest.__init__`'s non-keyword-only signature, silently shifting the
positional slots of `n_jobs`, `behaviour`, `random_state`, and `verbose`. FVK appended it
at the end (exactly as gold did), and located the regression by **formalizing
positional-call compatibility as an obligation** over the public signature, not by running
more tests.

> NOTE on the original investigation hint: the hint's hypothesis ("baseline added
> `warm_start` but didn't pass it through to `BaseBagging`, so `warm_start=True` had no
> effect") is **factually wrong** for this instance. Both baseline and fvk forward
> `warm_start=warm_start` to `super().__init__(...)`. The real defect fvk fixed is a
> *positional-argument shift*, described below.

| Arm | [`test_isolation_forest_positional_arg_compat`](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/test_fvk_regression.py#L26) | Resolved |
|---|---|---|
| baseline | [**FAIL (RED)**](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/_proof/baseline.report.json) | no |
| **fvk** | [**PASS (GREEN)**](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/_proof/fvk.report.json) | **yes** |

(No `gold.report.json` exists for this instance; gold's source change is otherwise
byte-for-byte identical to fvk — see §5.)

## 1. The issue and the real defect

The issue — *"Expose warm_start in Isolation forest"* — asks to expose `warm_start=False`
in `IsolationForest.__init__()`, forward it to the parent `BaseBagging`, and document it
RandomForest-style
([`problem_statement.md`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/problem_statement.md#L1)).
`IsolationForest` already inherits a working `warm_start` implementation from
`BaseBagging`; only the public constructor exposure was missing.

The original (pre-fix) constructor is **not keyword-only** (no bare `*`):

```python
def __init__(self, n_estimators=100, max_samples="auto", contamination="legacy",
             max_features=1., bootstrap=False, n_jobs=None, behaviour='old',
             random_state=None, verbose=0):
```

At this repo's version (v0.21) every parameter is legitimately addressable positionally, so
**inserting a new parameter mid-list is a public-API break** — every old positional call
binds the wrong values.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/solutions/solution_baseline.patch)
got the functional part right — it exposed the parameter and forwarded it:

> *"Added `warm_start=False` to the public `IsolationForest.__init__` signature. Passed
> `warm_start=warm_start` into `BaseBagging.__init__` so the inherited warm-start behavior
> is configured at construction time."*
> — [`reports/baseline_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/reports/baseline_notes.md#L16)

But baseline inserted `warm_start=False` **between `bootstrap=False` and `n_jobs=None`**.
New order: `… bootstrap, warm_start, n_jobs, behaviour, random_state, verbose`. Because the
constructor is not keyword-only, positions 6–9 all shift; every pre-existing positional
call binds the wrong arguments. The obligation baseline left unmet: **adding the new
parameter must not remap the old positional slots.**

## 3. How FVK formally captured the gap

FVK started from an intent spec that explicitly names backward compatibility, not just the
feature request:

> *"The API change should preserve existing public constructor usage. In particular,
> adding a new optional parameter must not remap the old positional parameters `n_jobs`,
> `behaviour`, `random_state`, and `verbose`."*
> — [`fvk/INTENT_SPEC.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/INTENT_SPEC.md#L17)

The evidence ledger pins that intent to two concrete facts found by source audit — the
correct placement modeled by the sibling estimator, and the compatibility fact that the
signature is positional:

> **E6:** *`repo/sklearn/ensemble/forest.py` — `RandomForestClassifier.__init__` lists
> `warm_start=False` after `verbose=0` … parameter placement should align with the named
> comparison estimator where compatible. Encoded by PO4 and PO5.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12)

> **E7:** *Existing constructor positional parameters are public API in this version
> because the signature is not keyword-only → New optional parameter should not shift old
> positional arguments. Generated Finding F1; fixed in V2 by appending `warm_start`.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13)

These discharge into a formal obligation:

> **PO4 - Positional compatibility.** *The new optional parameter must not shift old
> positional constructor arguments. Evidence: E7. Discharged by: V2 appends `warm_start`
> after `verbose`; K claim `IFOREST-POSITIONAL-COMPAT`. V1 status: failed. See Finding F1.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PROOF_OBLIGATIONS.md#L33)

This is the crux: the regression was located by **reasoning about the public signature**.
The feature request says only "expose `warm_start`"; FVK lifts that into a compatibility
obligation (E7: positional slots are public because there is no bare `*`) and the audit of
the sibling estimator (E6: append after `verbose`) tells it where the parameter belongs.

## 4. From formal output to the fix

The repair is iterative, and the artifacts record the exact step where the formalism
changed the patch.

- **V1** exposed and forwarded `warm_start` but inserted it before `n_jobs` (identical to
  what baseline shipped).
- The completeness audit against the spec raised a finding:

  > **F1 - V1 shifted old positional constructor arguments.** *Cause: V1 inserted
  > `warm_start` before `n_jobs`. Because this version's constructor is not keyword-only,
  > that is a public API regression. Resolution: V2 appends `warm_start=False` after
  > `verbose=0`, preserving the old positional mapping …*
  > — [`fvk/FINDINGS.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/FINDINGS.md#L5)

- The iteration guidance turned the finding into the code decision:

  > *"V1 should not stand exactly as written because Finding F1 showed a positional
  > compatibility regression. V2 keeps the V1 behavioral fix but moves `warm_start=False`
  > to the end of the `IsolationForest.__init__` signature after `verbose=0`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/ITERATION_GUIDANCE.md#L7)

- The decision log records the change and its provenance:

  > **Decision 2: Changed the V1 parameter placement: moved `warm_start` from before
  > `n_jobs` to after `verbose`.** *Trace: F1. Proof obligation: PO4. Rationale: V1 enabled
  > the keyword but shifted old positional calls. V2 preserves old positional mapping and
  > still enables the new keyword.*
  > — [`reports/fvk_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/reports/fvk_notes.md#L12)

The causal chain is fully on the record:

```
INTENT item 5  ->  E6 (RandomForest appends after verbose) + E7 (positional slots are public API)
               ->  F1 (V1 audit: insert before n_jobs shifts old positions)
               ->  PO4 (obligation: do not shift old positional args)
               ->  ITERATION_GUIDANCE / Decision 2  ->  V2 patch
```

The resulting
[V2 patch](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/solutions/solution_fvk.patch)
appends the parameter after `verbose`:

```python
-                 verbose=0):
+                 verbose=0,
+                 warm_start=False):
```

The `V1 -> V2` transition was driven by `F1`/`PO4`, **not** by a new failing test — the
issue's own `test_iforest_warm_start` uses all-keyword args, which ignore positional order
(see §5).

## 5. Verification

**Harness (official SWE-bench Docker).** A regression test for the positional contract was
run against the baseline and fvk trees
([baseline](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/_proof/baseline.report.json) →
**RED**,
[fvk](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/_proof/fvk.report.json) →
**GREEN**). No `gold.report.json` was produced for this instance; gold's source change is
byte-for-byte identical to fvk apart from one cosmetic docstring line (see below), so gold
would also be GREEN.

**Behavioral demonstration.** A user writing against the original public API (intending
`n_jobs=3, behaviour="new", random_state=0, verbose=1`):

```python
IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)
```

Positional binding under each variant:

| param | user intent | baseline (WRONG) | fvk / gold (RIGHT) |
|---|---|---|---|
| warm_start | False | **3** (truthy → spurious warm-start) | False |
| n_jobs | 3 | **"new"** | 3 |
| behaviour | "new" | **0** | "new" |
| random_state | 0 | **1** | 0 |
| verbose | 1 | **0** (arg 9 unbound) | 1 |

Under baseline the object is silently misconfigured: `n_jobs="new"` raises `TypeError`
inside joblib at `fit` time; `behaviour=0` is not validated (`fit` only checks
`if self.behaviour == 'old'`), so it is silently treated as "new"; `warm_start=3` is truthy
and wrongly triggers warm-start branching. Under fvk every argument lands where intended.

**Why the suite missed it.** FAIL_TO_PASS `test_iforest_warm_start` calls
`IsolationForest(..., warm_start=True)` with **all keyword args** — keyword binding ignores
parameter order, so it passes identically under both arms. A scan of `test_iforest.py`
shows no `IsolationForest(...)` call uses positional args at position 6+, so the regression
is invisible to grading.

**Gold comparison.** Both fvk and gold append `warm_start` after `verbose`. Diffing
[`fvk.patch`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/fvk.patch)
vs [`gold.patch`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/gold.patch),
the only difference is one docstring line gold adds (`.. versionadded:: 0.21`); the source
change is otherwise byte-for-byte gold. Gold's deliberate *append* (not insert) confirms
the maintainers cared about positional compatibility — exactly what baseline broke and fvk
restored.

## 6. Boundaries & honesty

- **Severity: Low.** The regression lives entirely in the positional contract. Modern
  sklearn (≥0.24) made many constructors keyword-only and discourages positional calls, so
  a user passing 6+ positional args is uncommon — the trigger breadth is narrow. But at
  this repo's version the positional API is public and supported, and gold treats it as
  worth preserving, so this is a legitimate backward-compat correctness fix, not cosmetics.
  The value demonstrated is **detection power**, not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-iforest-api.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/mini-iforest-api.k),
  [`iforest-warm-start-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/iforest-warm-start-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning**, not a machine-checked proof. The fix's
  correctness is independently confirmed by the harness RED→GREEN above.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the patch delta is observed directly. The
  original investigation hint's pass-through hypothesis is wrong (see NOTE in Summary) —
  the real, narrower defect is the positional shift.

## Artifact map

| Claim | Source |
|---|---|
| Issue text | [`_materials/problem_statement.md`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/problem_statement.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/reports/baseline_notes.md#L16) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/solutions/solution_fvk.patch), [`_materials/fvk.patch`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/scikit-learn__scikit-learn-13496/_materials/gold.patch) |
| Intent (positional compat) | [`fvk/INTENT_SPEC.md#L17`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/INTENT_SPEC.md#L17) |
| Evidence E6 (placement) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L12`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12) |
| Evidence E7 (public positional API) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L13`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PUBLIC_EVIDENCE_LEDGER.md#L13) |
| Obligation PO4 | [`fvk/PROOF_OBLIGATIONS.md#L33`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PROOF_OBLIGATIONS.md#L33) |
| Finding F1 | [`fvk/FINDINGS.md#L5`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/FINDINGS.md#L5) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace 2 | [`reports/fvk_notes.md#L12`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/reports/fvk_notes.md#L12) |
| Constructed K core | [`fvk/mini-iforest-api.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/mini-iforest-api.k), [`fvk/iforest-warm-start-spec.k`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/iforest-warm-start-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified037-codex-wsl-ubuntu-260615221107/scikit-learn__scikit-learn-13496/fvk/PROOF.md#L3) |
| Harness RED/GREEN verdicts | [`enhanced_tests/_proof/`](../verified500_analysis/scikit-learn__scikit-learn-13496/enhanced_tests/_proof/) |
