# Control notes — pydata__xarray-6992 (post-review)

This documents the audit of the V1 fix and the resulting decisions. Every
decision is traced to a numbered entry in `review/FINDINGS.md`.

## Summary of the final fix

`repo/xarray/core/dataset.py`, `Dataset.reset_index` — two coupled changes:

```python
# 1) keep coord_names a subset of variables (V1, kept)
coord_names = (set(new_variables) | self._coord_names) - set(drop_variables)

# 2) recompute dims so dropped dimensions are not left stale (V2, added)
return self._replace_with_new_dims(
    variables, coord_names=coord_names, indexes=indexes
)
```

(V1 had been `coord_names = set(new_variables) | self._coord_names` followed by
`return self._replace(variables, coord_names=coord_names, indexes=indexes)`.)

## Decision 1 — Keep V1's `coord_names` subtraction (unchanged)

Traces to **F1**. This is the direct fix for the reported bug
(`DataVariables.__len__` going negative). It restores the invariant
`_coord_names ⊆ _variables.keys()`, which the test infrastructure asserts
explicitly (`testing.py::_assert_dataset_invariants` line 352). The review
re-derived that the post-condition holds for all input shapes, and **F5**
confirms the subtraction never removes a legitimately kept coordinate because
`drop_variables` (names in `dims_or_levels`) and `new_variables` (kept multi-
index levels, i.e. names *not* in `dims_or_levels`) are always disjoint. No
reason to change it; kept verbatim.

## Decision 2 — Switch `_replace` → `_replace_with_new_dims` (new change)

Traces to **F2**. This is the one concrete defect the review surfaced. The test
infrastructure also asserts `_dims.keys() == {dims used by variables}`
(`_assert_dataset_invariants` line 362). V1 returned through `_replace`, which
copies `self._dims` unchanged, so a `drop=True` that removes the last variable
on a dimension leaves that dimension orphaned in `_dims` and fails the invariant
(e.g. `Dataset(coords={"x":[1,2,3]}).reset_index("x", drop=True)`).

`_replace_with_new_dims` recomputes dims via `calculate_dimensions(variables)`,
whose keys equal exactly the set of dimensions used by the surviving variables
(verified in `variable.py:3104`). This satisfies the invariant. It is the same
helper `set_index` already uses (codebase-consistent, per **F4** the change is
idiomatic), forwards `attrs`/`indexes`/`encoding` identically to the previous
`_replace` call (so only dims behavior changes), and cannot raise a spurious
size-conflict because `reset_index` never alters a surviving variable's dims or
sizes.

Why this is safe for everything else (per **F2**/**F4**): in every `drop=False`
call no variable is dropped, so recomputed dims equal the old dims; and in every
visible `drop=True` test at least one variable (a data variable, or a surviving
multi-index level) keeps each dimension referenced, so recomputed dims again
equal the old dims. The behavior changes *only* in the previously-crashing
orphan case, where the new result (drop the empty dimension) is the correct one.

## Decision 3 — Do NOT convert reset coordinates to base `Variable`s (deliberate non-change)

Traces to **F3**. A plausible "improvement" would convert the now-index-less
coordinates to base `Variable`s. The review rejected this: invariant lines
366-370 / 333-335 require any variable with `v.dims == (k,)` (i.e. a dimension
coordinate such as the multi-index `x`) to remain an `IndexVariable`. Converting
it would fail the dataset/dataarray invariants, and the expected objects in the
existing tests are themselves auto-promoted to `IndexVariable` for that
coordinate. V1 already keeps the original `IndexVariable`s, which is correct, so
no change was made here.

## Decision 4 — Leave `drop=False` path and surrounding logic untouched

Traces to **F4**, **F6**, **F7**. `drop=False` is byte-for-byte equivalent to
the original code (F4). `DataArray.reset_index` delegates to the Dataset method
and is fixed transparently; it also cannot hit the orphan case because the main
data variable always survives (F6). Multi-index level reductions via
`keep_levels` continue to register a valid `PandasIndex` and satisfy the index
wrapper invariants (F7). None of these needed modification.

## Decision 5 — Out-of-scope observations left as-is

Traces to **F8**. Duplicate entries in `drop_indexes`/`drop_variables` are
harmless (membership tests + `set(...)`); `index not in replaced_indexes` is
pre-existing index-refactor code; keeping the full multi-index coordinate after
dropping a single level with `drop=True` is pre-existing, internally consistent,
and untested behavior. Changing any of these would be unrelated churn, so they
were intentionally not touched, keeping the fix minimal and targeted.

## Net effect

The fix now upholds **both** `Dataset` structural invariants that the hidden
test harness checks on every compared object — `_coord_names ⊆ _variables`
(Decision 1) and `_dims == dims-of-variables` (Decision 2) — across all
`reset_index` paths, including the issue's MVCE and the
drop-the-last-coordinate-of-a-dimension edge case, with no change to any
`drop=False` behavior.
