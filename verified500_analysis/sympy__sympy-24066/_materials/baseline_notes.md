# Baseline Notes

## Root cause

`UnitSystem._collect_factor_and_dimension()` collected a raw `Dimension`
expression for function arguments and returned that expression as the
function's result dimension. In the reported SI example,
`second/(ohm*farad)` collected as `Dimension(time/(capacitance*impedance))`.
That expression is dimensionless after expansion through the SI dimension
system, but it is not structurally equal to `Dimension(1)`.

When the expression appeared inside `exp()` and was added to `100`, the
addition branch compared dimensions structurally. It therefore rejected
`Dimension(time/(capacitance*impedance))` even though
`SI.get_dimension_system().is_dimensionless()` can prove that dimension has no
base-dimensional dependencies.

## Files changed

`repo/sympy/physics/units/unitsystem.py`

- In the `Add` branch of `_collect_factor_and_dimension()`, dimensions that are
  not structurally equal are now checked with the active dimension system's
  `equivalent_dims()` before raising `ValueError`. This keeps incompatible
  additions rejected while allowing derived dimensions that reduce to the same
  base-dimensional dependencies.
- In the `Function` branch, collected argument dimensions that the active
  dimension system proves dimensionless are normalized to `Dimension(1)` before
  being returned as the function result dimension. This makes
  `exp(second/(ohm*farad))` dimensionless under SI instead of carrying the raw
  derived-dimension expression.

## Assumptions and alternatives

- I assumed the correct behavior is to use the configured `DimensionSystem` as
  the source of truth for dimensionlessness and dimensional equivalence, rather
  than relying on structural equality of `Dimension.name` expressions.
- I kept the existing non-strict behavior for functions with dimensionful
  arguments. For example, the patch does not make `_collect_factor_and_dimension`
  reject every `exp()` or `log()` with a dimensional argument. That stricter
  interpretation would be a broader behavioral change and is not necessary for
  the reported issue.
- I considered canonicalizing every collected dimension to `Dimension(1)` when
  dimensionless, but rejected that as broader than required. The patch targets
  the function result and additive compatibility paths involved in the
  reproducer.
- I did not add or modify tests because the task requires changing non-test
  source code only.
