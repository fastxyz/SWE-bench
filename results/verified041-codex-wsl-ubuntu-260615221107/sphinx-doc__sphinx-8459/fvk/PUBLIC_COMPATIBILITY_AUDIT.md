# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

No public function, method, class, event name, config value, return shape, or callback
signature was changed by V1.

## Internal call compatibility

* `record_typehints()` keeps the same event callback signature:
  `(app, objtype, name, obj, options, args, retann)`.
* The changed call target is `sphinx.util.inspect.signature()`, whose local signature
  already accepts `type_aliases`. Multiple existing autodoc call sites pass
  `self.config.autodoc_type_aliases` to it.
* `app.config.autodoc_type_aliases` is registered by autodoc setup with default `{}`.

## Producer/consumer compatibility

* Producer: `record_typehints()` still stores strings in `app.env.temp_data['annotations']`.
* Consumer: `merge_typehints()` and `modify_field_list()` still consume the same
  `Dict[str, str]` shape.
* The only changed value is the intended string for aliased annotations.

Compatibility result: pass. No additional source edit is required.
