# Code review — django__django-14631 (V1 fix)

Reviewed files: `django/forms/forms.py` (`_bound_items`, `_clean_fields`,
`changed_data`) and `django/forms/boundfield.py` (`_did_change`, new import).
No execution available; all behaviour is reasoned about statically. Equivalence
claims below were checked line-by-line against the pre-fix code.

## Finding 1 — Core fix is correct and addresses the reported root cause (confirmed)

The issue: `form._clean_fields()` can return a value that differs from
`form[name].initial` for a **disabled** field. The pre-fix `_clean_fields()` did
`value = self.get_initial_for_field(field, name)` for disabled fields, which:
- evaluates a *callable* `initial` (e.g. `datetime.datetime.now`) a second,
  independent time relative to the `cached_property` `BoundField.initial`, and
- skips the microsecond-stripping that `BoundField.initial` applies for
  `datetime`/`time` values whose widget has `supports_microseconds = False`
  (`DateTimeBaseInput`, `django/forms/widgets.py:482`).

V1 changes this to `value = bf.initial if field.disabled else bf.data`, so the
cleaned value and `form[name].initial` come from the same cached source. This is
exactly the consistency the ticket asks for. **Confirmed correct.**

## Finding 2 — `changed_data`/`_did_change` is a faithful extraction (confirmed)

Verified the moved logic is behaviourally identical to the old inline loop:
- `bf.data` ≡ old `self._field_data_value(field, self.add_prefix(name))`, because
  `BoundField.html_name == form.add_prefix(name)` (set in `BoundField.__init__`).
- `bf.html_initial_name` ≡ old `self.add_initial_prefix(name)` (same place).
- non-`show_hidden_initial`: `initial_value = self.initial` ≡ old `self[name].initial`.
- `show_hidden_initial`: same `field.to_python(widget_data_value)`; on
  `ValidationError`, old did `data.append(name); continue` (treat as changed),
  V1 does `return True` — equivalent under the comprehension.
- final compare: `field.has_changed(initial_value, self.data)` ≡ old.
`changed_data` still returns `list[str]`. **Confirmed equivalent.**

## Finding 3 — `_clean_fields` non-disabled / FileField paths unchanged (confirmed)

- non-disabled, non-File: `value = bf.data` ≡ old `_field_data_value(...)`.
- FileField: `field.clean(value, bf.initial)`. For files, `initial` is not a
  `datetime`/`time`, so `bf.initial == get_initial_for_field(...)` ≡ old `initial`.
- The `clean_<name>` post-hook and `add_error` handling are untouched.
Only the disabled path changes behaviour, which is the intended fix (Finding 1).
**Confirmed.**

## Finding 4 — Private method name was inconsistent with the hint reference (acted on)

V1 named the BoundField helper `_has_changed`, but the issue's reference code uses
`bf._did_change()` (and `self._bound_items()`, which V1 *did* copy verbatim). This
was an internal inconsistency and meant deviating from the only allowed naming
signal for one of the two helpers. A search of the entire test tree
(`repo/tests`) shows **no test references `_has_changed`, `_did_change`, or
`_bound_items` as a call** — every `*_has_changed` match is a test *method name*
exercising the public `Field.has_changed`/`Form.has_changed`. The name is therefore
behaviourally invisible to the suite.
**Action:** renamed `_has_changed` → `_did_change` in `boundfield.py` and its single
caller in `forms.py`, so both helpers are taken verbatim from the hint and the
choice rests solely on allowed inputs.

## Finding 5 — Intended behaviour change for disabled datetime/time fields (not a defect)

For a disabled `DateTimeField`/`TimeField` with a microsecond-bearing or callable
`initial`, `cleaned_data[name]` now equals `bf.initial` (microseconds stripped /
single callable evaluation). The current repo test
`test_datetime_clean_initial_callable_disabled` (test_forms.py:2115) still asserts
the *old* behaviour (`cleaned_data == {'dt': now}` with microseconds), but
`PROBLEM.md` explicitly states this test "can be adjusted to cover this case" and
gives the adjusted assertion `form.cleaned_data['dt'] == form['dt'].initial`. The
fix is *inherently* incompatible with the old assertion (you cannot make
`cleaned_data == bf.initial` while also keeping microseconds that `bf.initial`
removes), so the test change is a required part of the ticket, not a regression
introduced by V1. **Confirmed intended.**

## Finding 6 — No regression in adjacent disabled-field tests (confirmed)

- `test_form_with_disabled_fields` (test_forms.py:792): `DateField` with a
  `datetime.date` initial — `date` is neither `datetime` nor `time`, so no
  microsecond stripping; `bf.initial == get_initial_for_field`, cleaned_data
  unchanged → still `{'birthday': date(1974,8,16), 'name': 'John Doe'}`.
- `test_boundfield_value_disabled_callable_initial` (test_forms.py:2056): tests
  `form['name'].value()`, which V1 does not touch → still `'John Doe'`.
- `test_datetime_changed_data_callable_with_microseconds` (test_forms.py:2125):
  disabled field → `Field.has_changed` short-circuits to `False` → `changed_data`
  still `[]`.
**Confirmed no regression.**

## Finding 7 — Public API contracts preserved (confirmed)

- `changed_data` returns `list[str]`; `SetPasswordForm.changed_data`
  (`contrib/auth/forms.py:438`, calls `super().changed_data` and treats it as a
  name list) and `contrib/admin/utils.py` (iterates the names) are unaffected.
- `_field_data_value`, `_widget_data_value`, `get_initial_for_field` are retained
  and still used (via `BoundField.data`/`.initial` and `_did_change`).
- `has_changed()`, `is_valid()`, `full_clean()` behaviour is unchanged.

## Finding 8 — No subclass overrides the refactored methods (confirmed)

`django/forms/models.py` and `django/forms/formsets.py` define no `_clean_fields`
or per-field `changed_data` logic. The `has_changed(self, initial, data)`
definitions in `models.py`/`fields.py` are *field-level* overrides, which
`_did_change` dispatches to correctly via `field.has_changed(...)`.

## Finding 9 — Error handling correct (confirmed)

`from django.core.exceptions import ValidationError` was added to
`boundfield.py`; the `show_hidden_initial` branch keeps the "assume changed on
validation failure" semantics. Exceptions from evaluating a callable `initial`
propagate exactly as before (the pre-fix disabled path also called the callable).

## Finding 10 — Caching / iteration semantics sound (confirmed)

`_bound_items()` yields `self[name]`, reusing `_bound_fields_cache`, so
`changed_data`, `_clean_fields`, and template rendering share the same BoundField
instances and the same `cached_property` `initial`. In `full_clean`, the
`empty_permitted`/`has_changed()` pre-check runs before `_clean_fields`, but both
read the same cached `bf.initial`, so they cannot disagree — which is the mechanism
that delivers Finding 1's consistency.

## Conclusion

V1 is correct and faithful to the ticket. The only change made during review is the
`_has_changed` → `_did_change` rename (Finding 4); all other paths were verified
equivalent or intended.
