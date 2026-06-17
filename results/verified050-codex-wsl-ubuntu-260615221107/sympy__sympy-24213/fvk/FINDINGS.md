# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and proof-obligation construction only.

## FVK-F1: Original Equivalent-Dimension Addition Bug

Input: collected addends `(a1*t1 -> factor -49, dimension acceleration*time)`
and `(v1 -> factor 2, dimension velocity)` under SI.

Pre-V1 observed behavior: `ValueError`, because the `Add` branch compared
`Dimension(acceleration*time)` and `Dimension(velocity)` by raw equality.

Expected behavior: accept the addition, because SI dimensional dependencies for
both dimensions are `{length: 1, time: -1}`.

Status: fixed by V1. The current code consults
`dimension_system.equivalent_dims(dim, addend_dim)` when dimensions are not
directly equal. Covered by PO-1, PO-2, and PO-7.

## FVK-F2: General Equivalent-Dimension Family

Input family: any `Add` whose collected addend dimensions are unequal as
objects but equivalent under the active `DimensionSystem`.

Observed in V1: the `ValueError` guard is skipped when
`equivalent_dims(first_dim, addend_dim)` is true.

Expected behavior: accept all such addends, not just `velocity` and
`acceleration*time`.

Status: confirmed for the specified family by the generalized proof obligation
PO-2.

## FVK-F3: Incompatible Additions Still Reject

Input: length plus time under a dimension system.

Expected behavior: raise `ValueError`, preserving unit-consistency behavior.

Observed in V1 by inspection: direct equality is false and
`equivalent_dims(length, time)` is false, so the existing `ValueError` branch
still runs.

Status: no regression found. Covered by PO-3.

## FVK-F4: Return Dimension Is Not Canonicalized

Input: an accepted addition where the first dimension is a compound expression
and a later addend is an equivalent named dimension.

Observed in V1: the returned dimension remains the first addend's dimension.

Expected behavior: preserve existing return shape and first-dimension behavior;
the public issue only requires detection of equivalence, not canonicalization.

Status: not a bug. Covered by PO-4 and PO-5.

## FVK-F5: Constructed Proof Only

Input: the FVK K claims in `fvk/collect-factor-and-dimension-spec.k`.

Observed: no K tooling was run, per task constraints.

Expected: artifacts must label the proof as constructed, not machine-checked,
and must not recommend deleting tests without a later `kprove` run.

Status: residual verification caveat, not a source-code bug. Covered by PO-8.
