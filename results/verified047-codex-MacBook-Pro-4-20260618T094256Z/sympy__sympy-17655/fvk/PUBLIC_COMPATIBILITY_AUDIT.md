# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public/Dispatch Surface

`Point._op_priority`

- V1 sets `Point._op_priority = 10.0001`.
- Compatibility requirement: win over plain `Expr` priority `10.0` so SymPy
  scalar-left multiplication can call `Point.__rmul__`.
- Regression check: remain below public higher-priority arithmetic families
  observed in source, including matrix-like `10.001`/`10.01`, matrix expression
  `11.0`, vector/dyadic `12+`, tensor/unit-style higher priorities, and related
  non-scalar objects.
- FVK trace: `HIGHER-PRIORITY-FRAME` in `point-scalar-mul-spec.k`.

`Point.__rmul__`

- New reflected multiplication method.
- Compatibility requirement: for scalar-left `Expr * Point`, return the same
  coordinate-wise point scaling as `Point * Expr`.
- FVK trace: `POINT-RMUL` and `POINT-RMUL-DIRECT`.

`Point.__radd__` and `Point.__rsub__`

- V1 overrides inherited `GeometryEntity` methods to prevent recursion when
  `_op_priority` causes `Expr`-left add/sub dispatch to enter `Point`.
- Compatibility requirement: direct point-to-point reflected behavior remains
  available for non-`Expr` operands. Public tests directly exercise
  `p1.__radd__(p2)` and `__rsub__`.
- FVK trace: `RADD-FRAME`, `RSUB-FRAME`, and the non-`Expr` delegation noted in
  `SPEC.md`.

`Point.__rdiv__`

- V1 overrides inherited `GeometryEntity.__rdiv__` to prevent recursion for
  `Expr`-left division once `_op_priority` is present.
- Compatibility requirement: preserve symbolic `Expr.__div__` shape; the issue
  does not require numeric point division from the left.
- FVK trace: `RDIV-FRAME`.

## Conclusion

No public compatibility audit item produced a regression-free, finding-backed
reason to edit V1. The reflected add/sub/div guards are necessary companions to
the priority change, and the chosen priority is bounded to avoid stealing known
higher-priority arithmetic dispatch.
