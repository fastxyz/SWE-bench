# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`repo/sympy/core/relational.py`: `Relational._eval_as_set(self)`

- Signature changed: no.
- Return type surface changed: only for the documented solver-incomplete path,
  from leaking `NotImplementedError` to returning a `ConditionSet`.
- Exact successful solver return values changed: no.
- New required arguments to virtual methods: no.
- New callsites of `solve_univariate_inequality`: no.

## Public Callers and Overrides

Static search found the public routing call in `Boolean.as_set()`:

- `repo/sympy/logic/boolalg.py`: calls `r._eval_as_set()` for periodic
  replacement checks and calls `self.subs(reps)._eval_as_set()` for the
  univariate final conversion.

Static search also found `_eval_as_set()` implementations on Boolean operators
(`And`, `Or`, `Not`, etc.), but V1 does not alter their signatures or dispatch.
No public override is required to accept new arguments because no new arguments
were introduced.

## Producer/Consumer Compatibility

Consumer: `Boolean.as_set()`

- Non-periodic univariate relational: receiving `ConditionSet` is the intended
  public result for an unsolved relation.
- Periodic relationals: `Boolean.as_set()` still rejects non-trivial periodic
  sets. V1 does not alter that branch.
- Multivariate expressions: unchanged and still rejected before reaching
  `_eval_as_set()`.

Producer: `solve_univariate_inequality`

- API unchanged.
- Documented `NotImplementedError` behavior remains available to direct callers.
- V1 handles that exception only at the `Relational._eval_as_set()` boundary.

## Compatibility Result

No public callsite or override requires a source change. No compatibility finding
forces a V2 edit.
