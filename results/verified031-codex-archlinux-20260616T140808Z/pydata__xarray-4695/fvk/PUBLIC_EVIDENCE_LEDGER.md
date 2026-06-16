# Public Evidence Ledger

## E1 - Reported Failure

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: `Naming a dimension "method" throws error when calling ".loc"`
- Semantic obligation: `.loc` must work when a selected dimension is named
  `method`.
- Status: encoded by `PO-1`, `PO-2`, and K claim `LOC-METHOD-CONCRETE`.

## E2 - Reproducer Pair

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: `D1.loc[dict(dim1='x', dim2='a')]` works while
  `D2.loc[dict(dim1='x', method='a')]` does not.
- Semantic obligation: replacing dimension name `dim2` with `method` must not
  change `.loc` dispatch behavior.
- Status: encoded by `PO-1` and finding `FVK-F1`.

## E3 - Name Irrelevance

- Source: `benchmark/PROBLEM.md`
- Quoted evidence: `The name of the dimension should be irrelevant.`
- Semantic obligation: dynamically constructed dimension names must remain
  indexer keys even when they collide with `.sel` parameter names.
- Status: encoded by `PO-1`, `PO-4`, and finding `FVK-F2`.

## E4 - Symptom Localization

- Source: public traceback in `benchmark/PROBLEM.md`
- Quoted evidence: `return self.data_array.sel(**key)` followed by
  `ValueError: Invalid fill method`.
- Semantic obligation: the failure mechanism is keyword unpacking of indexer
  mappings into `.sel`, not pandas label lookup itself.
- Status: encoded by diagnostic K claim `LEGACY-METHOD-COUNTEREXAMPLE` and
  findings `FVK-F1` and `FVK-F2`.

## E5 - Documentation: `.loc` Mapping Form

- Source: `repo/doc/indexing.rst`
- Quoted evidence: `da.loc[dict(space='IA')]` is listed under by-name,
  by-label indexing.
- Semantic obligation: a dictionary argument to `.loc` is an indexer mapping.
- Status: encoded by `PO-2`.

## E6 - Documentation: `.loc` Is Label Based

- Source: `repo/doc/indexing.rst`
- Quoted evidence: `To do label based indexing, use the ... DataArray.loc`
  attribute.
- Semantic obligation: `.loc` dispatch should perform exact label selection
  unless downstream `.sel` options are explicitly supplied by APIs that support
  them.
- Status: encoded by `PO-5`.

## E7 - `.sel` API Separation

- Source: `repo/xarray/core/dataarray.py`
- Quoted evidence: `.sel(self, indexers=None, method=None, tolerance=None,
  drop=False, **indexers_kwargs)`.
- Semantic obligation: the positional `indexers` mapping is separate from
  reserved `.sel` options.
- Status: encoded by `PO-2`, `PO-4`, and `PO-5`.

## E8 - Existing Correct Pattern

- Source: `repo/xarray/core/dataset.py`
- Quoted evidence: `return self.dataset.sel(key)` in `Dataset._LocIndexer`.
- Semantic obligation: passing the mapping positionally is already the local
  pattern for `.loc` dictionary lookup.
- Status: encoded by `PO-6`; used as compatibility evidence.
