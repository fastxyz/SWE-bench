# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep the V1 design: selectors under pandas output should slice the original `DataFrame` after validation, rather than cast a homogeneous computed array back to original dtypes.

Apply one V2 refinement from F2 and `PO-INVALID-CONFIG-ORDER`: defer output-config-dependent routing until after validation and avoid raising invalid output config from raw `SelectorMixin.transform`. This keeps compatibility closer to the existing `_SetOutputMixin` wrapper architecture.

## Recommended Additional Public Tests

Do not edit tests in this task. For future work, add tests covering:

- `SelectKBest(...).set_output(transform="pandas")` with mixed `float16` and `category` DataFrame columns, asserting selected dtypes equal the corresponding input dtypes.
- `fit_transform` and separate `fit(...).transform(...)` for the same mixed-dtype DataFrame.
- `k=0` or another all-false support selector with pandas output, asserting a pandas zero-column result with the input index.
- Default output with pandas input remains non-pandas.
- Invalid output config still follows existing wrapper error behavior when raw transform otherwise succeeds.

## No Further Code Changes Recommended

The remaining possible broader change, generic dtype preservation in `_SetOutputMixin`, conflicts with F3 and `PO-SCOPE-LIMIT`. Do not implement it without a separate public design decision.
