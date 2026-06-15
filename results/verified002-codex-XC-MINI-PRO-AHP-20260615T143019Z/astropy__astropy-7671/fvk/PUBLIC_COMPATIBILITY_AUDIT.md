# Public Compatibility Audit

Status: source-level compatibility audit for the V1 fix.

## Changed Public Symbols

No public symbol signature changed. The public function remains:

```python
minversion(module, version, inclusive=True, version_path='__version__')
```

## New Private Symbols

`_NUMERIC_VERSION_RE` and `_version_to_looseversion` are private implementation
details in `astropy.utils.introspection`.

## Callsite Audit

In-repo public callsites continue to call `minversion` with the existing
signature. Calls include numeric package version strings for NumPy, SciPy,
Matplotlib, and YAML compatibility checks. No callsite update is required.

## Behavior Compatibility

- Missing module import path still returns `False`.
- Invalid module argument type still raises `ValueError`.
- `version_path` lookup still happens before comparison.
- The changed behavior is limited to suffix-bearing numeric versions that
  previously could raise a `LooseVersion` `TypeError`.

Result: pass.

