# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is `PandasMultiIndexingAdapter.__array__` in
`repo/xarray/core/indexing.py`, plus the producer path in
`repo/xarray/core/indexes.py` that records and passes level coordinate dtype
metadata.

The property under verification is dtype preservation when a stacked MultiIndex
level coordinate is materialized as a NumPy array.

## Intent Ledger Summary

Full ledger: `PUBLIC_EVIDENCE_LEDGER.md`.

- E1 and E2 require stacked level coordinate values to preserve the dtype of the
  original index from which the MultiIndex was built.
- E3 identifies the adapter's stored dtype as the intended default conversion
  dtype.
- E4 and E5 show the existing producer path already records and supplies that
  dtype.
- E6 shows the base adapter convention: default `dtype` is `self.dtype`, then
  conversion uses `np.asarray(..., dtype=dtype)`.
- E7 prohibits test edits.

## Domain

For claims about a named MultiIndex level:

- the adapter has `level is not None`;
- `self.dtype` is the original coordinate dtype recorded by xarray;
- pandas can produce `self.array.get_level_values(self.level).values`;
- those values are castable to the effective dtype; and
- execution is in the normal `__array__` conversion path.

The `level is None` branch is covered as a compatibility claim.

## Contract

C1. Effective dtype:

```text
effective_dtype(self.dtype, requested_dtype) =
    self.dtype if requested_dtype is None
    requested_dtype otherwise
```

C2. Named level conversion:

```text
PandasMultiIndexingAdapter.__array__(requested_dtype)
    = np.asarray(
          self.array.get_level_values(self.level).values,
          dtype=effective_dtype(self.dtype, requested_dtype),
      )
```

C3. Default stacked coordinate dtype:

```text
if requested_dtype is None and self.dtype == original_coordinate_dtype:
    result.dtype == original_coordinate_dtype
```

C4. Explicit dtype override:

```text
if requested_dtype is not None:
    result.dtype == requested_dtype
```

C5. Non-level compatibility:

```text
if self.level is None:
    return super().__array__(requested_dtype)
```

## Formal Artifacts

- `mini-python-indexing.k` models the minimal dtype/value conversion fragment.
- `pandas-multi-indexing-adapter-spec.k` states the four K claims:
  `MI-ARRAY-DEFAULT-LEVEL-DTYPE`, `MI-ARRAY-EXPLICIT-DTYPE`,
  `STACKED-LEVEL-VALUES-DTYPE`, and `MI-ARRAY-NONLEVEL-DELEGATES`.

