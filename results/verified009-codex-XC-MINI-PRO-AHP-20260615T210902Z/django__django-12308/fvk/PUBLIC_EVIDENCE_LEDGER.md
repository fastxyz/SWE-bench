# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "JSONField are not properly displayed in admin when they are readonly." | Add/audit JSONField-specific readonly display behavior. |
| E2 | `benchmark/PROBLEM.md` | "`{\"foo\": \"bar\"}` would be displayed as `{'foo': 'bar'}`, which is not valid JSON." | JSON object values must display as JSON, not Python repr. |
| E3 | `benchmark/PROBLEM.md` | "call the prepare_value of the JSONField (not calling json.dumps directly to take care of the InvalidJSONInput case)." | Delegate to form preparation and preserve invalid JSON input. |
| E4 | `benchmark/PROBLEM.md` public hint | Coupling `contrib.postgres` with admin and type-name checks are problematic; use built-in `django.db.models.JSONField` instance checks. | Use `isinstance(field, models.JSONField)` and support inheritance. |
| E5 | `repo/django/db/models/fields/json.py` | `formfield()` passes `form_class: forms.JSONField`, `encoder`, and `decoder`. | Model field form preparation carries encoder configuration. |
| E6 | `repo/django/forms/fields.py` | `prepare_value()` returns `InvalidJSONInput` unchanged; otherwise `json.dumps(value, cls=self.encoder)`. | Invalid JSON input is not serialized again. |
| E7 | `repo/tests/admin_utils/tests.py` and `repo/django/contrib/admin/utils.py` | Admin utility tests cover `display_for_field(None, ...)`; the helper has `elif value is None: return empty_value_display`. | Preserve existing empty display behavior for `None`. |
| E8 | `repo/django/contrib/postgres/fields/jsonb.py` | `class JSONField(BuiltinJSONField)`. | The `models.JSONField` instance check covers deprecated postgres JSONField. |
| E9 | `repo/django/contrib/admin/helpers.py`, `repo/django/contrib/admin/templatetags/admin_list.py` | Callers invoke `display_for_field(value, f, empty_value_display)`. | Do not change the public helper signature. |
