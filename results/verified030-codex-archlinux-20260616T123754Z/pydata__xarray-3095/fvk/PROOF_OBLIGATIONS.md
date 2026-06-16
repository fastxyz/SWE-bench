# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Adapter dtype is the observable dtype

For any `PandasIndexAdapter A`, `A.dtype` returns the adapter's stored `_dtype`.
`A.__array__` also defaults to that dtype. Therefore, preserving xarray-visible
dtype requires preserving `_dtype`, not merely preserving the underlying
`pandas.Index`.

Evidence: `repo/xarray/core/indexing.py`, `PandasIndexAdapter.__init__`,
`dtype`, and `__array__`.

Discharged by: V1 passes `dtype=self._data.dtype` when rebuilding the adapter.

Finding trace: F-001.

## PO-2: Shallow IndexVariable copy preserves adapter dtype

For `IndexVariable.copy(deep=False, data=None)`, the implementation assigns
`data = self._data`, so the result is constructed from the same
`PandasIndexAdapter`. Its dtype is unchanged.

Evidence: `repo/xarray/core/variable.py`, `IndexVariable.copy`.

Discharged by: existing shallow branch; no V2 source edit required.

Finding trace: F-002.

## PO-3: Deep IndexVariable copy preserves adapter dtype

For `IndexVariable.copy(deep=True, data=None)`, the result must satisfy
`result.dtype == self.dtype` for all adapter dtypes, including `<U*>` where the
underlying pandas index may report `object`.

V1 branch:

```python
data = PandasIndexAdapter(self._data.array.copy(deep=True),
                          dtype=self._data.dtype)
```

The constructor stores the supplied dtype as `_dtype`, so the result adapter
reports the original dtype.

Discharged by: V1 source line above and K claim C1/C3.

Finding trace: F-001.

## PO-4: Dataset copy composes variable copy obligations

For `Dataset.copy(deep=True, data=None)`, every variable is copied with
`v.copy(deep=deep)`. Thus a dimension coordinate stored as `IndexVariable`
inherits PO-3. Non-index unicode data variables use `Variable.copy`, which copies
NumPy arrays directly and does not rebuild a `PandasIndexAdapter`.

Evidence: `repo/xarray/core/dataset.py`, `Dataset.copy`.

Discharged by: PO-3 for index coordinates and unchanged `Variable.copy` for
non-index variables.

Finding trace: F-001.

## PO-5: DataArray copy composes coordinate copy obligations

For `DataArray.copy(deep=True, data=None)`, the primary variable is copied and
each coordinate is copied with `v.copy(deep=deep)`. The reported issue's `x`
coordinate is an `IndexVariable`, so it inherits PO-3.

Evidence: `repo/xarray/core/dataarray.py`, `DataArray.copy`.

Discharged by: PO-3 for index coordinates.

Finding trace: F-001.

## PO-6: `copy.deepcopy` reaches the fixed deep branch

`__deepcopy__` delegates to `copy(deep=True)` for `Variable`, `Dataset`, and
`DataArray`. Therefore deep-copy dtype preservation follows from PO-3, PO-4, and
PO-5.

Evidence: `__deepcopy__` implementations in `repo/xarray/core/variable.py`,
`dataset.py`, and `dataarray.py`.

Discharged by: V1 and composition obligations.

Finding trace: F-001.

## PO-7: Public compatibility is preserved

V1 does not change any method signature, return type, public class, or caller
protocol. It only supplies an existing optional constructor argument,
`PandasIndexAdapter(..., dtype=...)`, at one internal call site.

Evidence: `PandasIndexAdapter.__init__(self, array, dtype=None)`.

Discharged by: unchanged public API surface.

Finding trace: F-002.

## PO-8: Proof status is honest

Because the task forbids executing K tooling, the proof must remain labeled
constructed, not machine-checked, and tests must not be removed.

Discharged by: `PROOF.md` command section and `FINDINGS.md` F-003.
