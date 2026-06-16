# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: MRO completeness for class mark lookup

Claim: for a class `C`, `get_unpacked_marks(C)` includes every direct
`pytestmark` value owned by every class in `C.__mro__`.

Public evidence: E1, E2, E3, E4, E5.

V1 mechanism: if `obj` is a class and `consider_mro=True`,
`get_unpacked_marks` builds `mark_lists` from each `x.__dict__.get("pytestmark",
[])` for `x in reversed(obj.__mro__)`, then normalizes the flattened list.

Status: discharged for completeness. Ordered sibling-base precedence is tracked
separately in PO6.

## PO2: Direct-only storage for newly applied class decorator marks

Claim: `store_mark(C, mark)` must append to marks directly stored on `C`, not to
the MRO-expanded view of `C`.

Public evidence: E6 and the no-sibling-bleed behavior covered by existing public
tests.

V1 mechanism: `store_mark` calls `get_unpacked_marks(obj,
consider_mro=False)`.

Status: discharged.

## PO3: No base or sibling mutation

Claim: applying a mark to `Sub(Base)` does not mutate `Base.pytestmark` and does
not make sibling classes inherit `Sub`'s mark.

Public evidence: E6.

V1 mechanism: `store_mark` reassigns `Sub.pytestmark` to a fresh list built from
direct marks plus the new mark. MRO lookup later reads base and subclass marks
without writing to bases.

Status: discharged.

## PO4: Non-class lookup frame condition

Claim: for non-class objects, `get_unpacked_marks` preserves the previous
`getattr(obj, "pytestmark", [])` behavior.

Public evidence: task scope is class MRO; existing marker APIs also apply to
functions/modules.

V1 mechanism: the `else` branch for non-classes is the original implementation.

Status: discharged by code inspection.

## PO5: Invalid mark normalization frame condition

Claim: invalid `pytestmark` entries still produce the same `TypeError` via
`normalize_mark_list`.

Public evidence: existing public test covers a wrong marker object.

V1 mechanism: all branches still return `normalize_mark_list(mark_list)`.

Status: discharged by code inspection.

## PO6: Sibling/base order policy

Claim candidate: the ordered list of inherited class marks should be either MRO
order, reverse-MRO order, or set-like without a promised order.

Public evidence: E2 requires both names but does not assert order. E7 documents
closest-first order at function/class/module levels, but does not directly settle
multiple base class ordering.

V1 mechanism: `reversed(obj.__mro__)` gives base-before-subclass and right-base
before left-base for sibling bases.

Status: ambiguous. Not used to justify the bug fix. Keep or add order tests only
after maintainers choose a policy.

## PO7: Public compatibility of signature changes

Claim: adding `consider_mro` must not break existing public or internal callsites.

Evidence: all existing callsites pass only `obj`; the new parameter is
keyword-only with a default.

V1 mechanism: signature is `get_unpacked_marks(obj: object, *, consider_mro:
bool = True)`.

Status: discharged by static callsite search.
