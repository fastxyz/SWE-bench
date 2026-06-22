# FVK Notes

## Summary

The FVK audit confirmed the V1 `DataArray.loc` fix and extended the same
mapping-form repair to two internal dynamic-selection helpers. The source now
avoids `.sel(**...)` in non-test package code, so dynamically derived dimension
names such as `method`, `tolerance`, and `drop` remain indexer keys instead of
reserved `.sel` parameters.

## Source Decisions

### `repo/xarray/core/dataarray.py`

Decision: keep the V1 change from `self.data_array.sel(**key)` to
`self.data_array.sel(key)`.

Trace:

- `fvk/FINDINGS.md` entry `FVK-F1` identifies the public `.loc` failure:
  `method="a"` was bound as the reserved fill-method parameter.
- `fvk/PROOF_OBLIGATIONS.md` entries `PO-2` and `PO-3` require both explicit
  mapping keys and expanded non-mapping `.loc` keys to use positional
  `.sel(indexers)`.
- `PO-5` requires `.loc` not to set `.sel(method=...)` from a dimension name.

### `repo/xarray/core/computation.py`

Decision: change `_iter_over_selections` from `obj.sel(**{dim: value})` to
`obj.sel({dim: value})`.

Trace:

- `FVK-F2` identifies the same dynamic dimension-name collision outside
  `.loc`.
- `PO-4` requires audited helpers that construct `{dim: value}` for dimension
  selection to pass that mapping positionally.
- `PO-6` confirms this does not change public signatures or introduce new
  virtual-dispatch keyword requirements.

### `repo/xarray/core/groupby.py`

Decision: change `GroupBy._yield_binary_applied` from
`other.sel(**{self._group.name: group_value})` to
`other.sel({self._group.name: group_value})`.

Trace:

- `FVK-F2` covers group or iteration dimensions named `method`.
- `PO-4` requires dynamic single-indexer helper dispatch to preserve the
  dimension name as data.
- `PO-5` requires exact selection options to remain framed unless explicitly
  supplied through the public `.sel` API.

## Decisions Not to Change

`DataArray.sel` and `Dataset.sel` signatures were left unchanged. `FVK-F3`
classifies direct `da.sel(method="a")` as an API ambiguity outside this repair;
`PO-5` and `PO-6` require preserving the documented reserved parameters and
public compatibility. The unambiguous direct form remains
`da.sel({"method": "a"})`.

No test files were modified and no tests, Python, or K tooling were run. This
follows `FVK-F4` and `PO-8`, and matches the task's no-execution constraint.

## Artifacts

The FVK package is under `fvk/`. The required benchmark artifacts are
`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and
`ITERATION_GUIDANCE.md`. The FVK method's adequacy and formal-core artifacts
are also present: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
`FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`,
`mini-python-loc.k`, and `dataarray-loc-spec.k`.
