# pydata__xarray-4695

- **Verdict:** CONFIRMED baseline-buggy. Both baseline and FVK have
  `resolved: true` in the official eval reports, but baseline fixed only the
  direct `.loc` call path. FVK fixed the same keyword-collision bug in internal
  dynamic selection helpers that still called `.sel(**{dim: value})`.
- **Primary FVK finding:** `FVK-F2 - Same Dynamic-Indexer Pattern Outside .loc`.
- **Proof status:** constructed, not machine-checked. The FVK artifacts provide
  K claims and proof obligations, but the recorded run did not execute `kprove`.

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue

xarray allows dimensions whose names collide with reserved `.sel()` keyword
parameters. A dimension can be named `method`, while `.sel()` also has a
reserved `method=` option for inexact matching. The reported bug is that
`DataArray.loc[...]` unpacked a mapping into `.sel(**key)`, so the dimension
name could be misread as the reserved `.sel(method=...)` argument.

The canonical failing shape is:

```python
DataArray(..., dims=["dim1", "method"]).loc[dict(dim1="x", method="a")]
```

The correct downstream call must preserve `"method"` as an indexer key:

```python
self.data_array.sel({"dim1": "x", "method": "a"})
```

not as a reserved option:

```python
self.data_array.sel(dim1="x", method="a")
```

## What baseline did

Baseline changed the direct `.loc` implementation in `xarray/core/dataarray.py`
from:

```python
return self.data_array.sel(**key)
```

to:

```python
return self.data_array.sel(key)
```

That fixes the official direct `.loc` regression test. It does not fix other
package code that constructs a dynamic one-item mapping and then unpacks it
into `.sel()`.

## Why baseline is buggy

The same invariant applies outside `.loc`: when a dimension name is data, it
must remain an indexer key. Baseline still had internal helpers doing:

```python
obj.sel(**{dim: value})
other.sel(**{self._group.name: group_value})
```

If `dim == "method"` or `self._group.name == "method"`, Python keyword
unpacking binds the value to the reserved `.sel(method=...)` option rather than
to a dimension indexer. The exact same class of bug therefore survives in
computation and groupby selection paths.

The problem is not limited to `method`; other reserved `.sel()` parameters such
as `tolerance` and `drop` are also unsafe when dynamic dimension names are
unpacked as keywords.

## What FVK changed and why

FVK kept the baseline `.loc` fix and additionally changed two internal helpers:

```python
obj.sel({dim: value})
other.sel({self._group.name: group_value})
```

The FVK formal argument is captured by the `HELPER-METHOD-CONCRETE` and
`HELPER-GENERIC` claims in `FORMAL_SPEC_ENGLISH.md`:

- a dynamically constructed one-item indexer with dimension name `"method"`
  reaches downstream `.sel` as `{"method": "a"}` with exact-match method state;
- for every dynamic dimension name `D` and label `V`, helper dispatch reaches
  downstream `.sel` with `{D: V}` as an indexer mapping.

That is the core proof obligation: dynamically derived dimension names are
data, not Python call-site option names.

## FVK Formal Argument

- **FVK status:** constructed, not machine-checked.
- **FVK formal argument:** PO-1/PO-4/PO-5 / `HELPER-METHOD-CONCRETE`: dynamically derived dimension names are data and must be passed as mapping indexers; exact `.sel()` options remain framed.
- **Why it catches baseline:** baseline fixes direct `.loc` dispatch but leaves internal helpers using `.sel(**{dim: value})`, so a dimension named like `method` can still bind as an option instead of an indexer.

## Concrete demonstration

Consider an internal helper iterating selections over a dimension named
`method`:

```python
dim = "method"
value = "a"
obj.sel(**{dim: value})
```

Baseline dispatches this as:

```python
obj.sel(method="a")
```

That is ambiguous and, under the public xarray API, means the inexact-match
method option. FVK dispatches it as:

```python
obj.sel({"method": "a"})
```

That is unambiguous and preserves `"method"` as a dimension key.

## Why the tests missed it

The official FAIL_TO_PASS test is:

```text
xarray/tests/test_dataarray.py::TestDataArray::test_loc_dim_name_collision_with_sel_params
```

It covers the direct `.loc[...]` path. It does not exercise `_iter_over_selections`
or groupby binary application with a colliding dimension/group name. Baseline
therefore passes the official test while leaving the same dispatch bug in those
additional public API paths.

## FVK vs. Human Fix

**Human fix issue:** partial.

The human fix covers the reported direct `.loc` call. FVK keeps that fix and extends the same mapping-dispatch invariant to computation and groupby helpers that still constructed dynamic `.sel(**{dim: value})` calls.


The official gold patch matches the direct `.loc` change:

```python
return self.data_array.sel(key)
```

Gold does not include the broader computation/groupby helper repair. That means
FVK is not a byte-for-byte gold match here. The stronger confirmation is the
source-level invariant: FVK found the same root keyword-collision pattern in
other dynamic selection call sites and applied the same mapping-form repair.

This case is retained because baseline remained concretely buggy after passing
the official tests, and FVK fixed the surviving bug with an explicit dispatch
invariant.


## Confidence and caveats

Confidence is high for the source-level bug: the baseline code still contains
the exact unsafe `.sel(**{dynamic_name: value})` pattern, and FVK changes it to
the same mapping-form dispatch used by the direct `.loc` fix.

The caveat is that the official gold patch only covered the direct `.loc` path.
The computation/groupby repairs are therefore confirmed by the FVK dispatch
obligation and source inspection rather than by gold equality.
