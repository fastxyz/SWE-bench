# FVK Specification

Status: constructed from public evidence and source inspection; not
machine-checked.

## Scope

This FVK pass audits the V1 change in
`repo/lib/matplotlib/colors.py`, inside `Colormap.__call__`, for integer
array/scalar inputs that are converted into lookup-table indices before
`lut.take(...)`.

The relevant implementation state is:

- `self.N` is the number of ordinary colormap entries.
- `self._i_under == self.N`, `self._i_over == self.N + 1`, and
  `self._i_bad == self.N + 2`.
- The lookup table contains ordinary entries followed by the three special
  under, over, and bad entries.
- `xa` is a copied array of input values and is later overwritten with the
  three special indices.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | problem | Expected outcome: "No warnings." | The reproduction with a `uint8` input must not emit NumPy out-of-bound integer conversion warnings. | Encoded by S-001 and S-004. |
| E-002 | problem | Actual warnings name assignments of 257, 256, and 258 into `uint8`. | The fix must address the sentinel assignments, not unrelated colormap behavior. | Encoded by S-001. |
| E-003 | public hint | "The problem is that there are three more values, that are by default out of range in this case" with default `N = 256`. | The formal model must include all three special lookup-table indices. | Encoded by S-002. |
| E-004 | public hint | "`xa` needs to be big enough to hold `self.N + 2` as values." | Before assigning sentinels, integer `xa` must have capacity for the largest sentinel. | Encoded by S-001. |
| E-005 | source docstring | Integer `X` values in `[0, Colormap.N)` return colormap entries indexed from the colormap. | In-range integer values must remain ordinary colormap indices. | Encoded by S-003. |
| E-006 | source implementation | The assignment order is over-range, then under-range, then bad mask. | The bad mask overrides range classification, matching current public behavior. | Encoded by S-002 and tracked as a frame condition. |

## Intent-Only Requirements

I-001: For integer input arrays, the index array used for lookup-table
selection must be able to represent all ordinary indices and the three special
indices `N`, `N + 1`, and `N + 2`.

I-002: For default `N == 256`, `uint8` input is in the intended domain and
must not trigger out-of-bound integer conversion warnings when sentinels are
assigned, including the empty-array reproduction.

I-003: Integer input values in `[0, N)` with no bad mask remain unchanged as
ordinary lookup-table indices.

I-004: Values classified as over, under, or bad map to the dedicated special
lookup-table entries, not to modulo-wrapped ordinary entries.

## Formal Domain

D-001: `self.N >= 0`, and the colormap has initialized sentinel indices
`U = N`, `O = N + 1`, and `B = N + 2`.

D-002: The lookup table has at least `N + 3` rows, so indices `0..B` are valid
lookup-table indices.

D-003: `X` is an integer NumPy array or scalar with dtype kind signed or
unsigned integer; `mask_bad` is scalar false or has the same shape as `X`.

D-004: NumPy can provide a promoted integer dtype whose representable maximum
is at least `B` for the colormap size under consideration. This is a
default-domain assumption for representable NumPy arrays and practical
colormap LUT sizes.

D-005: This proof slice concerns the integer branch. The existing float branch,
alpha handling, byte conversion, and `lut.take(...)` behavior are frame
conditions, not re-specified algorithms.

## Required Postconditions

S-001: Capacity. Immediately before the sentinel assignments, `xa` has an
integer dtype whose maximum representable value is at least `B = self._i_bad`.

S-002: Pointwise normalization. For each element with original integer value
`v` and bad-mask bit `bad`, the final lookup index is:

- `B` if `bad` is true;
- otherwise `O = N + 1` if `v > N - 1`;
- otherwise `U = N` if `v < 0`;
- otherwise `v`.

S-003: In-range frame condition. If `0 <= v < N` and `bad` is false, the
normalization step leaves the value `v` unchanged.

S-004: Warning-freedom for the reported class. Because each assigned sentinel
is representable in `xa`'s dtype at assignment time, assigning `U`, `O`, or
`B` does not rely on NumPy's deprecated out-of-bound integer conversion, even
when the boolean selection is empty.

S-005: API compatibility. The public signature, scalar-vs-array return rule,
output shape, alpha behavior, `bytes` behavior, and colormap lookup semantics
outside integer sentinel capacity are unchanged.

## Adequacy Check

The formal postconditions directly match the public issue and hint. The public
issue requires no warnings, but the hint strengthens that into the cause:
`xa` must be able to hold `self.N + 2`. Therefore this spec does not encode the
legacy modulo overflow behavior as expected behavior. It treats modulo wrapping
as the defect exposed by NumPy 1.24 warnings.

The only implementation-derived condition is the assignment order
over/under/bad. That order is part of existing public behavior and is not
changed by V1; it is used as a frame condition so the proof does not justify
unrelated behavior changes.
