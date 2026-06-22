# scikit-learn__scikit-learn-13496

- **Verdict:** C_ROBUSTNESS — baseline introduced a backward-incompatible API regression by inserting `warm_start` in the *middle* of `IsolationForest`'s non-keyword-only constructor, silently shifting the positional slots of `n_jobs`, `behaviour`, `random_state`, `verbose`; fvk appended it at the end (exactly as gold did), preserving positional compatibility.
- **Pitch-worthiness (1-5):** 4
- **Harness-verified regression test:** FAILS on baseline (RED), PASSES on FVK (GREEN), via the official SWE-bench Docker harness.

> NOTE on the original investigation hint: the hint's hypothesis ("baseline added `warm_start` to `__init__` but didn't pass it through to the parent `BaseBagging`, so `warm_start=True` had no effect") is **factually wrong** for this instance. Both baseline and fvk forward `warm_start=warm_start` to `super().__init__(...)`. The functional `warm_start=True` feature works identically in both. The real defect fvk fixed is a *positional-argument shift*, described below.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
`IsolationForest` inherits a working `warm_start` implementation from `BaseBagging` (whose `_fit` reuses `self.estimators_` and only builds `n_estimators - len(estimators_)` new trees when `warm_start=True`, else resets `estimators_` to `[]`), but never exposed `warm_start` in its own `__init__`. The issue asks to expose `warm_start=False`, forward it to the parent, and document it RandomForest-style.

The original (pre-fix) constructor is **not keyword-only** (no bare `*`):
```python
def __init__(self, n_estimators=100, max_samples="auto", contamination="legacy",
             max_features=1., bootstrap=False, n_jobs=None, behaviour='old',
             random_state=None, verbose=0):
```
So at v0.21 every parameter is legitimately addressable positionally — inserting one mid-list is a public-API break.

## What baseline did
Functionally correct, wrong place: baseline inserted `warm_start=False` **between `bootstrap=False` and `n_jobs=None`** and forwarded it. New order: `… bootstrap, warm_start, n_jobs, behaviour, random_state, verbose`. Because the constructor is not keyword-only, positions 5–8 all shift; every pre-existing positional call binds the wrong values.

## What fvk changed and why
fvk moved `warm_start=False` to the **end**, after `verbose=0`, leaving the parent-forward unchanged. This is the only diff vs baseline. `fvk_FINDINGS.md` F1 ("V1 shifted old positional constructor arguments") and `fvk_notes.md` decision #2 state this rationale correctly.

## FVK Formal Argument

- **FVK status:** constructed, not machine-checked.
- **FVK formal argument:** PO4 / `IFOREST-POSITIONAL-COMPAT`: adding `warm_start` is a public-call compatibility obligation; existing positional constructor slots must keep their meanings.
- **Why it catches baseline:** baseline inserts `warm_start` before existing positional parameters, so old positional callers silently bind later arguments to the wrong names.

## Concrete demonstration
A user writing against the original public API (intending `n_jobs=3, behaviour="new", random_state=0, verbose=1`):
```python
IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)
```
Positional binding under each variant (verified by a deterministic positional-binding trace):

| param | user intent | baseline (WRONG) | fvk / gold (RIGHT) |
|---|---|---|---|
| warm_start | False | **3** (truthy → spurious warm-start) | False |
| n_jobs | 3 | **"new"** | 3 |
| behaviour | "new" | **0** | "new" |
| random_state | 0 | **1** | 0 |
| verbose | 1 | **0** (arg 9 unbound) | 1 |

Under baseline the object is silently misconfigured. Concretely: `n_jobs="new"` raises `TypeError` inside joblib at `fit` time; `behaviour=0` is NOT validated (`fit` only checks `if self.behaviour == 'old'`), so `0 != 'old'` is silently treated as "new" — silent wrong behavior; `warm_start=3` is truthy and wrongly triggers warm-start branching. Under fvk every argument lands where intended and `warm_start` defaults to `False`.

## Why the tests missed it
- FAIL_TO_PASS `test_iforest_warm_start` calls `IsolationForest(n_estimators=10, max_samples=20, random_state=rng, warm_start=True)` then `clf.set_params(n_estimators=20)` — **all keyword args**. Keyword binding ignores parameter order, so it passes identically under baseline and fvk.
- A scan of the entire `test_iforest.py` (all PASS_TO_PASS): **no** `IsolationForest(...)` call uses positional args at position 6+. No hidden test exercises positional binding, so baseline's regression is invisible to grading.
- Classic "passes tests ≠ correct": the regression lives entirely in the positional contract, which the suite never touches.

## FVK vs. Human Fix

**Human fix issue:** no.

Both FVK and gold append `warm_start` to preserve existing positional constructor slots. Baseline inserts it in the middle, silently shifting public positional arguments.

Gold appends `warm_start` at the end, identical to fvk:
```python
-                 verbose=0):
+                 verbose=0,
+                 warm_start=False):
```
Diffing fvk.patch vs gold.patch, the ONLY difference is one cosmetic docstring line gold adds: `.. versionadded:: 0.21`. fvk's source change is otherwise byte-for-byte gold. Gold's deliberate append (not insert) confirms maintainers cared about positional compatibility — exactly what baseline broke and fvk restored. **GOLD_MATCH: yes.**

## Confidence & caveats
- **High confidence** the defect is real: original constructor has no bare `*` (verified against v0.21 source); the binding trace is deterministic.
- **Honest severity caveat:** modern sklearn (≥0.24) made many constructors keyword-only and discourages positional calls, so a user passing 6+ positional args is uncommon — practical blast radius is moderate, not catastrophic. But at this repo's version the positional API is public/supported and gold treats it as worth preserving, so this is a legitimate backward-compat correctness fix, not cosmetics.
