# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## Formal Core

The proof core is:

- `fvk/mini-roc.k`
- `fvk/roc-curve-spec.k`

The model is deliberately small. It proves the issue-relevant post-processing
contract: prepend an explicit sentinel to a list of observed finite thresholds.
The model is property-complete for the defect because it distinguishes:

- an observed finite probability threshold in `[0, 1]`;
- a fabricated finite threshold above 1;
- a non-finite sentinel `Inf`.

## P1: Symbolic Execution of V1 Sentinel Prepend

Initial symbolic state:

```k
<k> prependStart(TS) </k>
requires allProbFinite(TS)
```

The `mini-roc.k` rule rewrites:

```k
prependStart(TS) => Inf ; TS
```

This proves claim C1 and discharges PO-1 for the changed line: the formal
contract is about the artificial threshold, not about re-proving the producer
helper.

## P2: No-Prediction Sentinel

The predicate `scoreStrictlyAboveAll(Inf, TS)` rewrites to `true` for any
threshold list `TS` in `roc-curve-spec.k`. Therefore for every finite observed
score represented in the model, `Inf` is strictly above that score.

By the public `score >= threshold` rule, no finite score satisfies
`score >= Inf`. The first ROC point therefore selects no samples on normal
finite-score inputs and preserves the initial no-prediction semantics.

Discharges: PO-3.

## P3: Probability Boundedness of Finite Thresholds

Assume `allProbFinite(TS)`: every element of `TS` is `finite(I)` with
`0 <= I <= 1`. After P1 the result is `Inf ; TS`.

The predicate `rocProbabilityThresholds(Inf ; TS)` requires the first element
to be `Inf` and all remaining finite thresholds to satisfy `allProbFinite`.
Because P1 leaves `TS` unchanged and only prepends `Inf`, all finite thresholds
in the result remain in `[0, 1]`.

Discharges: PO-4.

## P4: Counterexample to Clipping

Consider the observed threshold list `finite(1) ; TS`, representing a
probability input with max score exactly 1. The clipping alternative modeled by
`clipPrependOne(finite(1) ; TS)` rewrites to:

```k
finite(1) ; finite(1) ; TS
```

The first threshold is not strictly above all observed scores because the next
score is also `finite(1)`. Under `score >= threshold`, that score would be
selected, so the first ROC point would not represent no predicted positives.

Discharges: PO-5 and supports FINDINGS F-3.

## P5: Legacy `max + 1` Counterexample

Consider the observed threshold list `finite(1) ; TS`. The legacy model
`legacyPrependPlusOne(finite(1), TS)` rewrites to:

```k
finite(2) ; finite(1) ; TS
```

The first threshold is finite and greater than 1, directly violating the
probability boundedness obligation for finite thresholds. This matches the
issue's described defect.

Supports: FINDINGS F-1 and PO-4.

## P6: Compatibility and Shape

In the source code, the same prepend operation is performed for `tps`, `fps`,
and `thresholds`:

```python
tps = np.r_[0, tps]
fps = np.r_[0, fps]
thresholds = np.r_[np.inf, thresholds]
```

Given PO-2, each output array length is the corresponding input length plus
one, so `fpr`, `tpr`, and `thresholds` remain shape-aligned. The public
function signature is unchanged.

Discharges: PO-6.

## Residual Risk

This is a partial correctness proof for the sentinel contract, constructed but
not machine-checked. It does not prove:

- termination;
- full Python/NumPy semantics;
- floating-point formatting;
- `_binary_clf_curve` sorting or cumulative sums;
- `drop_intermediate` correctness;
- one-class warning behavior.

Those limits are recorded as FINDINGS F-4 and PO-7. They do not justify a
source change to V1 because none of those behaviors were changed by V1.

## Machine-Check Commands

Do not run these in this benchmark session. They are the commands to run in an
environment with K installed:

```sh
cd fvk
kompile mini-roc.k --backend haskell
kast --backend haskell roc-curve-spec.k
kprove roc-curve-spec.k
```

Expected machine-check result: `kprove` reduces the claims to `#Top`.

## Test Recommendation

No tests were modified. Tests that only assert shape, no NaN values, or
threshold comparison consistency should be kept until machine-checking and the
normal project test suite run in a real environment.

Exact tests expecting a finite first threshold of `2.0` are SUSPECT legacy
tests under FINDINGS F-2. If test edits were allowed, they should be updated to
expect `np.inf`; they should not be removed solely on this constructed proof.
