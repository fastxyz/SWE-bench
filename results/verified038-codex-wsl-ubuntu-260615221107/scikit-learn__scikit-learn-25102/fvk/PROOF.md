# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Reproduce Later

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/selector-transform-spec.k
kprove fvk/selector-transform-spec.k
```

Expected machine-check result if the abstract semantics and claims are accepted: `#Top`.

## Proof Sketch

### `SELECTOR-PANDAS-PRESERVE`

Initial state:

```text
transform(df(I, cols(CS), dtypes(DS), values(VS)), M, pandas, true)
```

The semantics first rewrites to:

```text
validate(df(...)) ~> afterValidate(original_df, original_df, M, pandas, true)
```

Under the precondition `validForSelector(original_df)`, validation rewrites to a homogeneous array value. This models the legacy dtype-loss risk. The continuation then sees the original input, pandas config, and auto wrapping enabled. By the pandas-preserving rule it rewrites to:

```text
selectDataFrame(original_df, M)
```

The spec-level function rule for `selectDataFrame` gives:

```text
df(I,
   cols(selectList(CS, M)),
   dtypes(selectList(DS, M)),
   values(selectList(VS, M)))
```

Thus the selected output dtypes are selected from the original DataFrame dtype list, not from the homogeneous validated array dtype.

### `SELECTOR-DEFAULT-ARRAY`

For `default` output config, the pandas-preserving side condition is false. After validation, the transform rewrites to `selectArray(validated_X, M)`. This matches the legacy array path and proves default output is not changed into pandas output.

### `SELECTOR-EMPTY-PANDAS`

For `notBool anySelected(M)` on the pandas-preserving path, the transform rewrites to `emptyDataFrame(original_df, M)`. In code, this corresponds to the `not mask.any()` warning branch returning `_safe_indexing` on the original DataFrame instead of reading `X.dtype`, which DataFrames do not provide as a scalar dtype.

### `SELECTOR-EMPTY-ARRAY`

For `notBool anySelected(M)` outside the pandas-preserving path, the transform rewrites to `emptyArray(validated_X)`. In code, this is the preserved `np.empty(0, dtype=X.dtype).reshape((X.shape[0], 0))` branch.

### `INVALID-CONFIG-ORDER`

V1 attempted `_get_output_config` before validation. V2's helper catches invalid config and returns `False`, so raw transform does not enter the original-DataFrame branch on invalid config. If validation or raw transform has its own error, that error can still occur before wrapper-level output config validation, as in the pre-existing wrapping architecture. If raw transform succeeds, `_wrap_data_with_container` still calls `_get_output_config` and reports the invalid config.

## Verification Conditions

- `VC1`: `selectDataFrame(df(I, cols(CS), dtypes(DS), values(VS)), M)` preserves `I`. Discharged by function rule.
- `VC2`: selected output dtype list is `selectList(DS, M)`. Discharged by function rule and independent of validated homogeneous array dtype.
- `VC3`: default output path is selected when `configIsPandas(C) == false` or auto wrapping is false. Discharged by Boolean side condition.
- `VC4`: empty DataFrame branch avoids scalar `X.dtype`. Discharged by branch split on `anySelected(M)` and `isDataFrame(ORIG)`.
- `VC5`: invalid config does not select original DataFrame in raw transform. Discharged by `configIsPandas(invalid) => false` in the model and V2 helper behavior in source.

## Test-Redundancy Recommendation

No tests were run and no tests were modified. Because the proof is not machine-checked, no existing tests should be removed. A future unit test asserting dtype preservation for a mixed-dtype pandas `DataFrame` through `SelectKBest(...).set_output(transform="pandas")` would be subsumed by `SELECTOR-PANDAS-PRESERVE` only after `kprove` returns `#Top`; until then it should be kept.

Existing integration and compatibility tests around `set_output`, `ColumnTransformer`, empty selections, and selector dtype behavior remain valuable because this proof models only the selector transform core and not all pandas, NumPy, or pipeline integration behavior.

## Residual Risk

- Partial correctness only: termination is trivial for the modeled branch structure, but not machine-proved.
- The mini semantics abstracts pandas, NumPy, and scikit-learn validation details.
- The proof is constructed manually and not machine-checked.
- Hidden tests were not used and no evaluator output was consulted.
