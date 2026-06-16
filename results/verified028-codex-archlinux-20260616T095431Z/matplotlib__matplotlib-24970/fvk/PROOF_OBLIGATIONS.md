# FVK Proof Obligations

Status: constructed, not machine-checked. Commands that would be used in a
complete FVK environment are listed in `PROOF.md` and were not run.

## PO-001: Capacity establishment

Claim:

For integer `xa` with dtype capacity `C0` and largest sentinel
`B = self._i_bad = self.N + 2`, the V1 branch establishes a post-branch
capacity `C1 >= B`.

Reasoning obligation:

- If `B <= C0`, V1 leaves `xa` unchanged and `C1 == C0 >= B`.
- If `B > C0`, V1 casts with
  `np.promote_types(xa.dtype, np.min_scalar_type(B))`; for in-domain NumPy
  integer dtypes and practical colormap LUT sizes, that promoted dtype can
  represent `B`, so `C1 >= B`.

Evidence: SPEC E-004, D-004, S-001.

Status: discharged by source inspection under D-004.

## PO-002: Sentinel assignment safety

Claim:

Given PO-001, each assignment
`xa[xa > self.N - 1] = self._i_over`,
`xa[xa < 0] = self._i_under`, and
`xa[mask_bad] = self._i_bad` assigns a value representable by `xa`'s dtype.

Reasoning obligation:

`self._i_under = N`, `self._i_over = N + 1`, and `self._i_bad = N + 2`.
If the dtype can represent `B = N + 2`, it can represent the smaller
nonnegative sentinels `N` and `N + 1`.

Evidence: SPEC E-002, E-003, E-004, S-001, S-004.

Status: discharged by arithmetic ordering of sentinel values.

## PO-003: Pointwise special-index semantics

Claim:

For each integer element with original value `v` and bad-mask bit `bad`, the
post-assignment index is:

`bad ? B : (v > N - 1 ? O : (v < 0 ? U : v))`

where `U = N`, `O = N + 1`, and `B = N + 2`.

Reasoning obligation:

The code assigns over first, under second, and bad last. Therefore the bad mask
overrides any previous range classification. Values not selected by any mask
are not overwritten.

Evidence: SPEC E-005, E-006, S-002, S-003.

Status: discharged by assignment order and boolean mask semantics.

## PO-004: Empty-selection warning freedom

Claim:

The reported empty `uint8` input cannot trigger out-of-bound sentinel
conversion warnings after V1.

Reasoning obligation:

Even when a boolean selection is empty, NumPy validates the assigned scalar
against the array dtype. PO-001 ensures the dtype can represent the assigned
sentinel before all three assignments.

Evidence: SPEC E-001, E-002, S-004; Finding F-001.

Status: discharged from PO-001 and PO-002.

## PO-005: In-range frame condition

Claim:

For integer elements where `0 <= v < N` and `bad` is false, V1 leaves `v` as
the lookup-table index.

Reasoning obligation:

Such values fail the over mask, fail the under mask, and fail the bad mask.
The optional dtype cast changes representation capacity, not the mathematical
integer value.

Evidence: SPEC E-005, S-003.

Status: discharged by source inspection.

## PO-006: Public compatibility frame

Claim:

V1 does not change public API shape or non-integer-branch behavior.

Reasoning obligation:

The only source edit is inside the integer branch before sentinel assignment.
The method signature, float branch, `bytes` handling, `alpha` handling,
`lut.take(...)`, shape handling, and scalar return conversion are untouched.

Evidence: SPEC S-005; Finding F-004.

Status: discharged by diff inspection.

## PO-007: Proof honesty and model boundary

Claim:

The proof package is a constructed proof, not a machine-checked proof.

Reasoning obligation:

No test suite, Python snippet, NumPy runtime, `kompile`, or `kprove` execution
is available or allowed in this benchmark pass. The proof relies on a small
abstract model of NumPy integer dtype capacity and promotion.

Evidence: task constraints; Finding F-005.

Status: open as a machine-checking/runtime-validation boundary, not a V1 code
defect.
