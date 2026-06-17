# Iteration Guidance

Status: constructed, not machine-checked.

## Code outcome

V1 did address the reported issue, but FVK finding F2 exposed a robustness gap in
the way V1 called `DimensionSystem.equivalent_dims()` and `is_dimensionless()`
inline. V2 keeps V1's intended behavior and adds conservative private helpers:

- `_is_dimensionless()`;
- `_dimensions_equivalent()`.

No broader refactor is recommended.

## Tests to add in a normal development environment

Do not edit tests for this benchmark task. In a normal SymPy workflow, add tests
covering:

- `SI._collect_factor_and_dimension(100 + exp(second/(ohm*farad)))` returns a
  dimensionless result and does not raise.
- `SI._collect_factor_and_dimension(exp(second/(ohm*farad)))` returns
  `Dimension(1)` as the dimension.
- Existing incompatible additions such as `u + second` and `1 - exp(u / w)`
  still raise `ValueError`.
- A dimension expression that the dimension system cannot analyze does not get
  silently normalized to `Dimension(1)`.

## Machine-checking

Run these commands only in an environment where K exists:

```sh
kompile fvk/mini-sympy-units.k --backend haskell
kast --backend haskell fvk/unitsystem-collect-spec.k
kprove fvk/unitsystem-collect-spec.k
```

Keep the proof labeled "constructed, not machine-checked" until `kprove` returns
`#Top`.

## Residual risk

- The K model is a reduced collector model, not full Python or full SymPy
  semantics.
- No execution was performed, by task requirement.
- The collector still has pre-existing limitations for multi-argument functions;
  this issue does not require changing that behavior.
