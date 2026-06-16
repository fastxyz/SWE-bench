# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Symbols

`ColumnTransformer.set_output(self, *, transform=None)`

- Signature changed: no.
- Return value changed: no, still returns `self`.
- New virtual dispatch: no new virtual method name; it uses the existing
  `_safe_set_output(..., transform=...)` helper on a constructor parameter that
  is already an estimator-valued child.
- Public subclasses/overrides in `repo/sklearn`: none found for
  `ColumnTransformer`.
- Compatibility result: pass.

`_safe_set_output(estimator, *, transform=None)`

- Public API status: internal helper, but used by `Pipeline`,
  `FeatureUnion`, and `ColumnTransformer`.
- Signature changed: no.
- Non-`None` error behavior changed: no. A transformer without `set_output`
  still raises when `transform` is `"pandas"` or `"default"`.
- `None` behavior changed: yes, now explicitly returns without checking child
  `set_output`, matching the helper docstring that says `None` is a no-op.
- Compatibility result: pass; this removes an over-eager capability check for
  a documented no-op case.

## Public Callsite Search

Repository search found `_safe_set_output` callsites in:

- `repo/sklearn/compose/_column_transformer.py`
- `repo/sklearn/pipeline.py`

Both pass the same `transform` keyword and ignore the helper return value. The
V2 helper change is therefore callsite-compatible.
