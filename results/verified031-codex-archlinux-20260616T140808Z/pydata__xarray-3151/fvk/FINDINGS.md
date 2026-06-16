# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Original Bystander-Coordinate Defect Is Addressed

Classification: resolved code bug.

Input class: two or more datasets in the same data-variable group where at
least one coordinate dimension varies and is usable for concatenation, while
another coordinate dimension has identical indexes across all datasets but is
not monotonic.

Concrete public example: `x` chunks `[1, 2, 3]` and `[4, 5, 6, 7]`; identical
`y` coordinate `['a', 'c', 'b']`.

Observed legacy behavior: `ValueError: Resulting object does not have
monotonic global indexes along dimension y`.

Expected behavior: return without that error, because `y` does not vary between
datasets and is documented as ignored by `combine_by_coords`.

V1 audit result: confirmed. `_infer_concat_order_from_coords` excludes `y`
from `concat_dims`, and the V1 validation loop iterates over `concat_dims`
instead of every dimension in the concatenated result. Therefore `y`
non-monotonicity is no longer a cause of the final global-index error.

Trace: `SPEC.md` C1 and C3; `PROOF_OBLIGATIONS.md` PO-1, PO-2, and PO-3.

## F2: Impossible Ordering Along a Real Concat Dimension Remains Guarded

Classification: preserved required error behavior.

Input class: datasets whose varying coordinate dimension is selected for
concatenation, but whose combined global index is neither monotonic increasing
nor monotonic decreasing.

Concrete public test evidence: `x` chunks `[0, 1, 5]` and `[2, 3]` should raise
`ValueError` along dimension `x`.

Expected behavior: keep raising for the concat dimension because the automatic
coordinate ordering is impossible or ambiguous.

V1 audit result: confirmed. A varying coordinate dimension is appended to
`concat_dims`; the V1 validation loop still checks each dimension in
`concat_dims`; the original `ValueError` branch is unchanged inside that loop.

Trace: `SPEC.md` C2; `PROOF_OBLIGATIONS.md` PO-4.

## F3: No Public API Compatibility Issue Was Introduced

Classification: compatibility check passed.

Input class: all public callers of `combine_by_coords` using its existing
signature and keyword parameters.

Expected behavior: no API or call-shape change.

V1 audit result: confirmed. The patch changes only the iterable used by an
internal validation loop. Function signatures, keyword arguments, return
construction, grouping, merge behavior, and test files are unchanged.

Trace: `SPEC.md` C4; `PROOF_OBLIGATIONS.md` PO-5.

## F4: Residual Verification Caveat

Classification: proof capability and process caveat, not a code bug.

The proof is constructed by source inspection and obligation discharge, but it
has not been machine-checked with K and no project code was executed. Test
removal is not recommended. Existing tests covering integration, merge
behavior, and impossible ordering should be kept.

Trace: `PROOF.md` honesty gate; `PROOF_OBLIGATIONS.md` PO-6.
