# Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found that the source changes are justified
by public intent and by the proof obligations.

## Why No Source Change Is Needed

- Finding F-001 is resolved by PO1 through PO4: scalar-left point
  multiplication now reaches the same coordinate-scaling post-state as right
  multiplication.
- Finding F-002 is resolved by PO5: reflected add/sub/div shims prevent the
  priority change from introducing recursive dispatch for ordinary
  `Expr`-left operations.
- Finding F-003 is resolved by PO6: the selected priority value is just above
  ordinary `Expr` priority and does not exceed higher-priority systems found
  in the static source scan.
- PO7 confirms the change stays point-specific and does not require modifying
  `GeometryEntity`, public subclasses, or tests.

## Suggested Tests For A Future Non-Benchmark Pass

Do not edit tests in this benchmark. If test changes are allowed later, add:

- `sympify(2.0) * Point(1, 1) == Point(1, 1) * sympify(2.0)`
- `Point(0, 0) + sympify(2.0) * Point(1, 1)` equals the right-multiply form
- `2 * Point(1, 1)` for Python numeric reflected multiplication
- `x * Point(1, 2)` for symbolic scalar reflected multiplication
- compatibility assertions for `x + Point(1, 2)`, `x - Point(1, 2)`, and
  `x / Point(1, 2)` preserving symbolic forms

## Next Verification Step

When an execution environment with K is available, run:

```sh
kompile fvk/mini-python-point.k --backend haskell
kast --backend haskell fvk/point-scalar-spec.k
kprove fvk/point-scalar-spec.k
```

Keep the result labeled "constructed, not machine-checked" until those commands
return `#Top`.
