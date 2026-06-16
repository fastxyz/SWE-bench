# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

No public symbol, function signature, class, method dispatch registration, return
container API, or import path was changed.

## Changed Implementation Surface

`repo/sympy/sets/handlers/intersection.py::intersection_sets(ImageSet, Set)` was
changed internally in the `other == S.Reals` branch.

## Compatibility Findings

- The dispatched function still accepts the same `(ImageSet, Set)` arguments and
  returns SymPy set objects.
- The branch still returns `None` for out-of-scope symbolic cases where the
  handler cannot decide the intersection.
- Existing denominator behavior for `ImageSet(Lambda(n, 1/n), S.Integers)` is
  preserved as an exclusion from a real subset proof.
- Public tests that encode the old complement result are SUSPECT under the issue
  intent and must not veto the production fix.

