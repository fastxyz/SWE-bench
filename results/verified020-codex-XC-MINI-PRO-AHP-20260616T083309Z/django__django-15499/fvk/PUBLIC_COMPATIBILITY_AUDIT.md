# PUBLIC COMPATIBILITY AUDIT

Status: constructed, not machine-checked.

Changed public symbol: none.

Changed method signature: none.

Changed return type of `CreateModel.reduce()`: no. The method already returns
either a list of operations or a boolean. V1 adds another list-returning case.

Callsite compatibility:

- `MigrationOptimizer.optimize_inner()` already handles list reduction results
  by replacing the original operation pair with the returned list.
- Existing callers of `CreateModel.reduce()` continue to receive one of the
  documented reduction shapes: list or boolean.

Constructor compatibility:

- V1 calls `CreateModel(...)` with existing keyword arguments: `fields`,
  `options`, `bases`, and `managers`.

Subclass/override compatibility:

- No virtual method signature was changed.
- No new keyword was passed to an override.

Status: pass. No compatibility finding blocks V1.
