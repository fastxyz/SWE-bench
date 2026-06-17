# FVK Notes

## Decision Summary

V1 stands unchanged. The audit found no additional source defect in the V1
patch.

## Trace To Findings And Obligations

The decision to keep the equivalence check is justified by FVK-F1 and FVK-F2:
the original issue and the generalized equivalent-dimension family are covered
by PO-1, PO-2, and PO-7.

The decision not to broaden compatibility further is justified by FVK-F3 and
PO-3: incompatible dimensions such as length and time must still raise
`ValueError`.

The decision not to canonicalize the returned dimension is justified by FVK-F4,
PO-4, and PO-5: the existing method returns the first addend's dimension
expression, and the public issue only requires detecting equivalence.

The decision to keep the `dimension_system is None` fallback is justified by
PO-6 and the compatibility audit: `UnitSystem` can exist without a dimension
system, so direct equality remains the only available compatibility predicate.

The decision not to modify tests or claim machine-checked verification is
justified by FVK-F5 and PO-8: this task forbids running tests or K tooling, and
the proof is constructed only.

## Source Changes In This Phase

No source files under `repo/` were changed during the FVK phase. The V1 patch in
`repo/sympy/physics/units/unitsystem.py` remains the final code fix.
