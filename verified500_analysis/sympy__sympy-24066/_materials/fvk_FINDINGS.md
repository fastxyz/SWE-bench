# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent,
static code inspection, and proof construction only.

## F1: V1 fixed the reported dimensionless exponential path

Evidence: intent ledger I1 through I4; proof obligation PO1 and PO2.

Input: `100 + exp(second/(ohm*farad))`.

Pre-fix observed behavior from the public issue: `ValueError` because
`exp(second/(farad*ohm))` collected as
`Dimension(time/(capacitance*impedance))`.

Expected behavior: the SI dimension system proves
`time/(capacitance*impedance)` has no base-dimensional dependencies, so the
exponential's collected dimension should be `Dimension(1)` and the addition to
`100` should not raise.

V1 status: addressed by normalizing function argument dimensions that are proven
dimensionless and by using dimensional equivalence in the `Add` branch.

V2 status: retained.

## F2: V1 equivalence checks could leak lower-level `TypeError`

Evidence: intent ledger I5 and I9; proof obligation PO3.

Input class: an `Add` containing dimensions that are structurally unequal and
whose dimensional dependencies cannot be computed by `DimensionSystem`, for
example a `Dimension` expression containing an unsupported dimensional function.

V1 observed by static inspection: the `Add` branch called
`dimsys.equivalent_dims(dim, addend_dim)` inline. If dependency analysis raised
`TypeError`, that lower-level exception could escape instead of following the
collector's established incompatible-addend `ValueError` path.

Expected behavior: uncertain or unsupported equivalence should not be accepted
as equivalent. The collector should reject the addend as incompatible with its
normal `ValueError` behavior.

V2 change: added `_dimensions_equivalent()` and `_is_dimensionless()` helpers
that treat `TypeError` as a negative result in these new normalization and
compatibility checks.

## F3: Strict function-argument validation is out of scope and contradicted by public behavior

Evidence: intent ledger I6 and I7; proof obligation PO5.

Input: `1 - exp(u / w)` where `u / w` has non-dimensionless units.

Existing public behavior: the collector raises `ValueError` when that function
result is added to a dimensionless number. Another public test expects
`exp(pH)` with a dimensionful collected argument to return a dimensionful result
rather than immediately rejecting the function call.

Rejected alternative: making `_collect_factor_and_dimension()` enforce that all
`exp`, `log`, or other non-trigonometric function arguments are dimensionless.

Reason: the issue only requires recognizing an argument already proven
dimensionless by the dimension system. Strict validation would be a broader
public behavior change.

## F4: Full SymPy/K machine verification remains open

Evidence: FVK constraints and proof obligation PO6.

The artifacts include K claims and exact commands, but the K toolchain was not
run. The proof is constructed over a reduced model of the relevant collector
branches, not over full Python or full SymPy semantics.

Recommended next step: run the recorded `kompile` and `kprove` commands in an
environment with K installed, and keep all public tests until that succeeds.
