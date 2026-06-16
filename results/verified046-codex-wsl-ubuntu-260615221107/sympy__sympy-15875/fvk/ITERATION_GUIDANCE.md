# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Code Decision

Do not keep V1 exactly as written. Apply the V2 tightening from Finding F2:
do not return `False` for a multi-term imaginary coefficient sum merely
because the coefficient-sum `is_zero` subquery returns `False`.

The implemented V2 rule is:

- use `im_zero` only when it is truthy, returning `True`;
- return `False` for one definitely imaginary term;
- return `False` for same-sign nonzero coefficient groups;
- otherwise return `None`.

## Tests To Add When Test Edits Are Allowed

Do not edit tests in this benchmark. In a normal development setting, add or
confirm tests for:

- `(-2*I + (1 + I)**2).is_zero is not False`, preferably `is None` unless
  assumptions become strong enough to prove `True`;
- `zero + I` remains `False`;
- `zero + r*I` remains `None`;
- an unevaluated cancellation of two imaginary terms does not return `False`.

## Tests To Keep

Keep all integration and matrix-rank tests. The FVK proof is local to
`Add._eval_is_zero` and is constructed, not machine-checked.

Do not remove public tests unless the K commands below are run and return
`#Top`, and the normal SymPy test environment confirms no broader regression.

## Machine Check To Run Later

```sh
kompile fvk/mini-add-is-zero.k --backend haskell
kast --backend haskell fvk/add-is-zero-spec.k
kprove fvk/add-is-zero-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for
all claims.

## Remaining Open Boundary

This FVK pass does not verify the entire SymPy assumptions framework. If a
future issue shows another unsound `is_zero` result from lower-level predicates
or from real-only Add expressions, start a new FVK pass scoped to that
predicate family rather than expanding this local proof silently.
