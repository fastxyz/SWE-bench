# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`compile_json_path_final_key()`

Compatibility status: new internal helper in `django/db/models/fields/json.py`.
It is not exported by `__all__`, and no public call sites existed before the
patch.

`HasKeyLookup.as_sql(..., final_key=True)`

Compatibility status: the added argument has a default. Existing call sites
that pass `(compiler, connection, template=...)` remain valid. The only new
callers using `final_key=False` are internal `KeyTransform` existence paths.

`HasKeyLookup.as_oracle(..., final_key=True)`

Compatibility status: the added argument has a default. Django's compiler can
continue calling the method with `(compiler, connection)`. Internal callers that
need transform path semantics pass `final_key=False`.

## Public callsite and override search

Relevant source search found `HasKey(...)` internal uses in
`KeyTransformIsNull` and `KeyTransformExact.as_oracle`; both are updated for V2.
`HasKey`, `HasKeys`, and `HasAnyKeys` do not override `as_sql()` or
`as_oracle()`, so the default argument preserves dispatch compatibility.

## Compatibility conclusion

No public API signature requires callers to pass the new flag. Existing backend
SQL behavior is framed except for the intended JSON path component selection.
