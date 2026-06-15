# Public Compatibility Audit

## Changed symbol

`django.forms.fields.Field.__deepcopy__(self, memo)`

## Compatibility result

Pass. The V1 fix changes only the method body. It does not change the method
name, arguments, return shape, exception behavior, or dispatch protocol.

## Public callsites and overrides reviewed

- `BaseForm.__init__()` uses `copy.deepcopy(self.base_fields)`, which reaches
  field `__deepcopy__()` implementations through Python's normal deepcopy
  protocol.
- `ChoiceField.__deepcopy__()` calls `super().__deepcopy__(memo)`.
- `MultiValueField.__deepcopy__()` calls `super().__deepcopy__(memo)`.
- `ModelChoiceField.__deepcopy__()` routes to `Field.__deepcopy__()` with
  `super(ChoiceField, self).__deepcopy__(memo)`.

These callsites keep the same invocation shape and benefit from the added
`error_messages` copy. No production caller requires an update.
