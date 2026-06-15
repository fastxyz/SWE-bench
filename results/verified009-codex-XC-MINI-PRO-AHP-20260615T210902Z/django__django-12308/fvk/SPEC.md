# FVK Specification: django__django-12308

Status: constructed, not machine-checked.

## Target

The audited unit is `django.contrib.admin.utils.display_for_field(value, field, empty_value_display)` as used by readonly admin fields and changelist rendering. The source fix under audit is the V1 branch:

```python
elif isinstance(field, models.JSONField):
    return field.formfield().prepare_value(value)
```

The formal scope is the observable display result for JSONField values. The model abstracts unrelated admin display branches but keeps the property axis that matters: JSON preparation versus Python `str()`/repr fallback, preservation of invalid JSON input, subclass handling, and existing empty-value handling.

## Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "JSONField are not properly displayed in admin when they are readonly." | `display_for_field()` must have a JSONField-specific readonly display path. | Encoded in C-JSON-NONINVALID and C-JSON-INVALID. |
| E2 | prompt | "`{\"foo\": \"bar\"}` would be displayed as `{'foo': 'bar'}`, which is not valid JSON." | A non-null JSON object value for a JSONField must not fall through to Python repr; it must display as prepared JSON text. | Encoded in C-JSON-EXAMPLE and C-JSON-NONINVALID. |
| E3 | prompt | "call the prepare_value of the JSONField (not calling json.dumps directly to take care of the InvalidJSONInput case)." | The admin branch must delegate to the JSON form field's `prepare_value()` behavior, including invalid-input preservation. | Encoded in C-JSON-INVALID. |
| E4 | public hint | A patch coupled to `contrib.postgres` or based on type name is brittle; after built-in `django.db.models.JSONField`, use instance checks. | The type predicate should be `isinstance(field, models.JSONField)` and must cover subclasses such as `contrib.postgres.fields.JSONField`. | Encoded in C-POSTGRES-SUBCLASS and compatibility audit. |
| E5 | source | `models.JSONField.formfield()` passes `form_class=forms.JSONField`, `encoder`, and `decoder`. | Delegating through `field.formfield()` preserves configured JSON encoder behavior instead of duplicating it in admin. | Encoded in C-JSON-NONINVALID. |
| E6 | source | `forms.JSONField.prepare_value()` returns `InvalidJSONInput` unchanged, else `json.dumps(value, cls=self.encoder)`. | Invalid submitted JSON must not be double-serialized or quoted by admin display. | Encoded in C-JSON-INVALID. |
| E7 | public tests/source | Admin utility tests describe `display_for_field` handling `None` values via `empty_value_display`; current function has the general `value is None` branch before type-specific formatting. | `None` remains an empty model value for admin display, including JSONField, unless choices/Boolean special cases already intercept it. | Encoded in C-JSON-NONE. |

## Contract

For `display_for_field(value, field, empty_value_display)`:

1. If `field` has choices, the pre-existing choices branch remains first and is outside this JSON-specific proof slice.
2. If `field` is a `models.BooleanField`, the pre-existing Boolean icon behavior remains unchanged.
3. If `value is None`, the result is `empty_value_display`.
4. If `field` is an instance of `models.JSONField` and `value is not None`, the result is exactly the result of `field.formfield().prepare_value(value)`.
5. If `field` is a subclass of `models.JSONField`, including `django.contrib.postgres.fields.JSONField`, the same JSONField branch is selected.
6. For an `InvalidJSONInput` value, the JSONField result is the original invalid JSON string, not `json.dumps()` output.
7. Non-JSON fields retain their existing downstream formatting behavior.

## Formal Model

Formal files:

* `fvk/mini-admin-display.k` defines a minimal K semantics for the branch behavior of `display_for_field()` and JSON form preparation.
* `fvk/admin-display-spec.k` defines reachability claims C-JSON-EXAMPLE, C-JSON-NONINVALID, C-JSON-INVALID, C-POSTGRES-SUBCLASS, C-POSTGRES-INVALID, C-JSON-NONE, and C-NONJSON-FALLBACK.

The model uses constructors such as `jsonField(ENC)`, `postgresJsonField(ENC)`, `invalidJson(S)`, `preparedJson(V, ENC)`, and `pyRepr(V)` to preserve the display distinction relevant to the issue. A Python repr result and a prepared JSON result are different observables in the formal model.

## Assumptions

* `field.formfield()` for `models.JSONField` returns a `forms.JSONField` configured with the model field encoder, per source evidence E5.
* `forms.InvalidJSONInput` is represented as `invalidJson(S)` and is in scope because the public issue explicitly names it.
* `None` is treated under admin's existing empty-value rule, not under JSON serialization, based on E7.
* The proof is partial correctness over the modeled branch behavior. There are no loops or recursion in the audited slice.
