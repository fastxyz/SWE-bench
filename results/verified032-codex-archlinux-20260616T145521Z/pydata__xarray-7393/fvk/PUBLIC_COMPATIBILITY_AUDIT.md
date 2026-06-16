# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`repo/xarray/core/indexing.py`: `PandasMultiIndexingAdapter.__array__`

## Signature Compatibility

The method signature remains:

```python
def __array__(self, dtype: DTypeLike = None) -> np.ndarray:
```

No caller needs a new argument, and the return type remains `np.ndarray`.

## Dispatch and Callers

The method participates in the NumPy `__array__` protocol. V1 preserves the
protocol shape and only changes the default dtype used in the `level is not
None` branch. Explicit dtype calls remain supported and now follow the same
effective dtype rule as the base adapter.

## Producer and Consumer Compatibility

`PandasMultiIndex.stack` and related constructors already record
`level_coords_dtype`, and `PandasMultiIndex.create_variables` already passes
that dtype to `PandasMultiIndexingAdapter`. V1 consumes that existing metadata
without changing the producer format.

For `level is None`, V1 still delegates to `PandasIndexingAdapter.__array__`,
so aggregate MultiIndex coordinate conversion is not given a new result shape.

## Tests

No test files were modified. Any test removal would be recommendation-only and
conditioned on a future machine check, but this benchmark forbids editing tests.

## Result

No public compatibility issue found.

