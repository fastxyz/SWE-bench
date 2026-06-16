# Public Compatibility Audit

Status: constructed from source inspection only; no code was executed.

Changed public symbol: `sympy.polys.monomials.itermonomials`.

## Signature

The signature remains `itermonomials(variables, max_degrees, min_degrees=None)`. No parameter was added, removed, renamed, or reordered.

## Return Shape

The function remains a generator. V2 changes only which monomials are yielded for integer total-degree filtering and the empty-variable positive-minimum boundary.

## Public Callsites

Source search found non-test callsites in:

- `repo/sympy/integrals/heurisch.py`
- `repo/sympy/polys/multivariate_resultants.py`

These callsites pass only `variables` and `max_degrees`, so `min_degrees` defaults to `0`. The V2 changes preserve default lower-bound behavior, including yielding `1` where degree `0` is in range.

## Overrides / Virtual Dispatch

`itermonomials` is a module-level function, not a virtual method. No subclass or override compatibility issue applies.

Compatibility finding: no public compatibility blocker. This supports proof obligation PO-8.
