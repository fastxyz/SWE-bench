# ITERATION GUIDANCE

Status: constructed for audit, not machine-checked.

## Decision

V1 did not fully stand. The FVK audit confirmed the parenthesis strategy from V1 but found a related empty-spread separator bug in the same fixer. V2 patches that bug.

## Applied Source Changes

1. `unnecessary_spread` now passes outer item position (`is_first`, `is_last`) into the fix builder.
2. `trailing_edits` now also returns the end offset of the removed closing wrapper tokens.
3. Empty spread dicts now use `empty_spread_edit`, which removes the whole empty spread item with the correct adjacent separator.
4. `following_item_start` and `trailing_comma_end` localize separator deletion for empty first/middle/only item cases.

## Next Human/Machine Verification

Run these only in an environment where execution is allowed:

```sh
kompile fvk/mini-pie800-fixer.k --backend haskell
kast --backend haskell fvk/unnecessary-spread-spec.k
kprove fvk/unnecessary-spread-spec.k
```

Then run the project tests relevant to PIE800 and autofix syntax validation.

## Recommended Test Cases

Do not edit tests in this benchmark pass, but future tests should cover:

- `{"data": [], **({"count": 1 if include_count else {}})}`
- `{**({}), "x": 1}`
- `{"x": 1, **({}), "y": 2}`
- `{"x": 1, **({})}`
- `{**({}),}`
- non-parenthesized versions of each empty-spread case;
- non-empty parenthesized spread with an inner trailing comma;
- non-empty parenthesized spread whose last value is itself parenthesized.

## Residual Risk

The formal model is token-shape-level, not a full Rust or Python semantics. It is adequate for the reported defect axis and the FVK-discovered separator defect, but a full proof would require running K and the Ruff test suite in an execution-enabled environment.
