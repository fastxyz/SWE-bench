# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`django.contrib.admin.checks.ModelAdminChecks._check_list_display_item(self, obj, item, label)`

- Signature: unchanged.
- Return shape: unchanged (`list` of zero or one `checks.Error` objects).
- Public error IDs: unchanged (`admin.E108`, `admin.E109`).
- Error message families: unchanged.
- Direct caller: `_check_list_display()` still calls the helper with
  `(obj, item, "list_display[%d]" % index)`.

## Callsite and Override Search

Repository search found the helper defined once and called directly by
`_check_list_display()`. No in-repository subclass override of
`_check_list_display_item()` was found.

## Behavior Compatibility

Preserved:

- Missing items still return `admin.E108`.
- Direct `ManyToManyField` items still return `admin.E109`.
- Callables, `ModelAdmin` attributes, regular model fields, and regular model
  attributes still pass.

Intentionally changed:

- A model field found by `_meta.get_field(item)` is validated before a
  same-named `ModelAdmin` attribute. This matches the public docs and runtime
  `lookup_field()` field-first order.
- A descriptor-backed field that cannot be accessed on the model class no
  longer produces a false `admin.E108`.

No public API signature or dispatch protocol change is introduced.

