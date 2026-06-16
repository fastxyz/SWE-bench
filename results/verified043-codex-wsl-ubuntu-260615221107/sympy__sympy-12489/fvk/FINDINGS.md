# FVK Findings

Status: constructed, not machine-checked.

## F1: Resolved Root Cause

Input/model: `Sub._af_new(valid_array)`.

Legacy observed behavior from issue: allocation used `Basic.__new__(Perm,
perm)`, so the result had class `Permutation`.

Expected behavior: allocation uses the class `_af_new` is called on, so the
result has class `Sub`.

V1 status: fixed. `Permutation._af_new` is now a classmethod and calls
`Basic.__new__(cls, perm)`.

Proof obligations: PO1.

## F2: Constructor Fast Paths Covered

Input/model: `Sub(...)` through empty, cycle-argument, `Cycle`, singleton, and
existing-permutation construction paths that allocate from array form.

Legacy observed risk: these paths called the module-level `_af_new` alias bound
to base `Permutation`.

Expected behavior: fresh allocation through `Sub.__new__` returns `Sub`.

V1 status: fixed. The audited branches now call `cls._af_new(...)`, and the
fallthrough allocation path already calls `Basic.__new__(cls, aform)`.

Proof obligations: PO2, PO3.

## F3: Existing Base-Alias Call Sites Remain Compatible

Input/model: external code that binds `_af_new = Permutation._af_new`, then
calls `_af_new(valid_array)`.

Expected behavior: these internal aliases continue to produce base
`Permutation` objects unless explicitly rebound from a subclass.

V1 status: confirmed. Because `Permutation._af_new` is bound at alias creation
time, these aliases keep `Permutation` as the bound class.

Proof obligations: PO5, PO7.

## F4: Subclass-Sensitive Operations Stand

Input/model: inherited operation invoked on a subclass instance and returning a
fresh permutation from an array form, e.g. inverse or multiplication.

Expected behavior: a method inherited by a subclass should not collapse the
fresh result back to base `Permutation` when the helper has access to the
receiver class.

V1 status: confirmed. Methods audited in V1 now use `self._af_new`,
`cls._af_new`, or `self.__class__` when constructing fresh results.

Proof obligations: PO4.

## F5: Proof Capability Boundary

Input/model: full SymPy permutation validation and algebraic operations.

Expected behavior: unchanged permutation mathematics and validation behavior.

V1 status: no source-level defect found in textual audit, but the mini-K model
does not prove full permutation algebra, validation, parsing, or termination.
Those remain covered by existing project tests and future machine-checking
against a fuller Python/SymPy semantics.

Classification: proof capability gap, not a V1 code bug.

Proof obligations: PO6, PO8.

## Conclusion

No FVK finding requires a V2 source edit. V1 stands.

