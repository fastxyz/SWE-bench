# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

Reasoning:

- F1 and PO2 show the original defect was subtracting zero-imaginary roots; V1
  fixes that by intersecting the base set with `FiniteSet(*roots)`.
- F2 shows the existing complement-style public test is SUSPECT and should not
  drive production behavior.
- F3 and PO3 show the denominator exclusion logic is required; V1 preserves and
  slightly repairs that path.
- F4 resolves the main audit concern about factor structure for the issue path.
- PO5 shows there is no public API compatibility change.

## Recommended Tests

Do not edit tests in this task. A future test patch should cover:

- `imageset(Lambda(n, n + (n - 1)*(n + 1)*I), S.Integers).intersect(S.Reals) == FiniteSet(-1, 1)`.
- `2 not in imageset(Lambda(n, n + (n - 1)*(n + 1)*I), S.Integers).intersect(S.Reals)`.
- `imageset(Lambda(n, 1/n), S.Integers).is_subset(S.Reals) is None`.

## Machine-Check Follow-Up

Run, outside this no-exec session:

```sh
kompile fvk/mini-sympy-sets.k --backend haskell
kast --backend haskell fvk/imageset-real-intersection-spec.k
kprove fvk/imageset-real-intersection-spec.k
```

Only after `kprove` returns `#Top` should any tests be considered redundant.

