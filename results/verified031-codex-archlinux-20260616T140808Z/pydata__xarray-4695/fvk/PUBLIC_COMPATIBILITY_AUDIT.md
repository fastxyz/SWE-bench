# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

None. No public function, method, class, or attribute signature was changed.

## Changed Call Shapes

### `DataArray._LocIndexer.__getitem__`

- Before V1: `self.data_array.sel(**key)`
- V1 and V2: `self.data_array.sel(key)`
- Public surface: `DataArray.loc[...]`
- Compatibility result: pass. `DataArray.sel` already accepts a positional
  `indexers` mapping, and `Dataset.loc` already uses the same shape.

### `_iter_over_selections`

- Before V2: `obj.sel(**{dim: value})`
- V2: `obj.sel({dim: value})`
- Public surface: internal helper used by computation/groupby application.
- Compatibility result: pass. `obj` is expected to be a Dataset or DataArray
  style object with `.sel(indexers=None, ...)`; no new keyword or signature
  requirement is introduced.

### `GroupBy._yield_binary_applied`

- Before V2: `other.sel(**{self._group.name: group_value})`
- V2: `other.sel({self._group.name: group_value})`
- Public surface: grouped binary operations.
- Compatibility result: pass. The call continues to invoke `.sel` with one
  indexer, but now uses the documented mapping form.

## Overrides and Virtual Dispatch

No changed method signature sends a new keyword to an override. The edits reduce
keyword dispatch rather than adding it.

## Producer/Consumer Shapes

The produced object passed to `.sel` remains a mapping from dimension name to
indexer value. The consumer is the existing positional `indexers` parameter.

## Compatibility Findings

No unhandled public callsite, override, or signature compatibility issue was
found in the audited source slice.
