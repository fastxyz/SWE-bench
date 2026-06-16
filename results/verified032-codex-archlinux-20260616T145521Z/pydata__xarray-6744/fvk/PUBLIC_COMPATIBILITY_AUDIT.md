# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

Changed public symbol:

- `DataArrayRolling.__iter__`

Compatibility checks:

- Signature: unchanged. The method still takes only `self` and returns an
  iterator of `(label, DataArray)` pairs.
- Yield shape: unchanged. Labels still come from `self.window_labels`; windows
  are still produced with `isel` slices of the original object.
- Error behavior: unchanged for `ndim > 1`; the existing `ValueError` remains.
- Non-centered behavior: preserved by PO-2.
- Centered behavior: intentionally changed to satisfy the public issue and docs.
- Overrides/subclasses: no in-repo subclass override of `DataArrayRolling.__iter__`
  was found in the audited source search; no virtual dispatch signature change
  was introduced.
- Tests: no test files were modified, per task constraints.

Verdict: no public compatibility blocker. The only behavior change is the
intended correction for `center=True` manual iteration.
