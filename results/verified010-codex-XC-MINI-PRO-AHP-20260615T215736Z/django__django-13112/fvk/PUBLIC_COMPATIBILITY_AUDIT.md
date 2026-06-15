# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: none.

Changed implementation site: `ForeignObject.deconstruct()` local construction of `kwargs["to"]` for string `remote_field.model` values.

Compatibility checks:

- Method signature: unchanged.
- Return shape: unchanged four-tuple `(name, path, args, kwargs)`.
- Constructor arguments emitted by deconstruction: unchanged keys except corrected value of `kwargs["to"]`.
- Swappable `SettingsReference` protocol: unchanged.
- Public tests: not modified.
- Subclass/override dispatch: no new virtual dispatch or keyword argument was added.

Verdict: compatible.

