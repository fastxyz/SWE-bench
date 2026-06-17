# Public Evidence Ledger

This file mirrors the ledger in `SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | prompt | "`SI._collect_factor_and_dimension() cannot properly detect that exponent is dimensionless`" | Use dimension-system knowledge for dimensionless function arguments. |
| I2 | prompt | `SI.get_dimension_system().is_dimensionless(dim)` is asserted for `second/(ohm*farad)` | Treat that collected dimension as dimensionless under SI. |
| I3 | prompt | Error says dimension should be `Dimension(1)` | Return `Dimension(1)` for the exponential result dimension. |
| I4 | prompt | `100 + exp(expr)` is the reproducer | The addition must not raise. |
| I5 | public test | Incompatible unit additions raise `ValueError` | Preserve incompatible-addition rejection. |
| I6 | public test | `1 - exp(u / w)` raises `ValueError` | Preserve rejection for function results with non-dimensionless dimensions. |
| I7 | public test | `exp(pH)` can collect with a dimensionful result | Do not introduce strict function validation. |
| I8 | source | `DimensionSystem.is_dimensionless()` checks dependency emptiness | Use the dimension system as the reduction oracle. |
| I9 | FVK audit | V1 inline dimension checks could leak `TypeError` | Add conservative helpers. |
