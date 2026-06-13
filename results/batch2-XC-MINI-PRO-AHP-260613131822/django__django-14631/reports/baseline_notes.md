# Baseline notes — django__django-14631

## Issue

`BaseForm._clean_fields()` and `BaseForm.changed_data` should access their values
through `BoundField` objects (like the rest of the form/template machinery) rather
than recomputing values directly from the field/data. The reported consequence is
that `form._clean_fields()` can produce a `cleaned_data[name]` that differs from
`form[name].initial` for a **disabled** field, even though they should be identical.

## Root cause

For a disabled field, the old `_clean_fields()` computed the value directly:

```python
if field.disabled:
    value = self.get_initial_for_field(field, name)   # NOT the BoundField's initial
```

`BoundField.initial`, however, is a `@cached_property` that does two extra things on
top of `get_initial_for_field()`:

1. It is **cached** — it evaluates a callable `initial` (e.g. `datetime.datetime.now`
   or `lambda: now`) exactly once. The old `_clean_fields()` called
   `get_initial_for_field()` again, a *second independent* evaluation. For a callable
   that returns the current time this yields a different value than the one later
   returned by `form[name].initial`.
2. It strips microseconds for `datetime`/`time` values when the widget does not
   support microseconds (`DateTimeBaseInput.supports_microseconds = False`, see
   `django/forms/widgets.py`). The old direct call kept the microseconds.

Because rendering (`BoundField.value()` → `field.bound_data()` for disabled fields)
already uses `BoundField.initial`, the cleaned value and the rendered/`form[name].initial`
value could diverge on both counts. `changed_data` had the same conceptual smell:
the per-field "did it change?" logic lived on the form and re-derived the data and
initial values instead of asking the `BoundField`.

## Changes

### `django/forms/forms.py`

- **Added `BaseForm._bound_items()`** — a small generator yielding `(name, bf)` pairs
  (`bf = self[name]`, which reuses the existing `_bound_fields_cache`). This gives both
  `_clean_fields()` and `changed_data` a single, consistent way to iterate fields as
  `BoundField`s.
- **Rewrote `_clean_fields()`** to iterate `self._bound_items()` and take its values
  from the `BoundField`:
  - `value = bf.initial if field.disabled else bf.data`
  - `FileField` now uses `bf.initial` as the `initial` argument to `field.clean()`.
  `bf.data` is exactly the old `self._field_data_value(field, self.add_prefix(name))`
  (since `bf.html_name == form.add_prefix(name)`), so the non-disabled path is
  behaviourally unchanged. The disabled path now shares the single cached
  `BoundField.initial`, fixing the divergence.
- **Rewrote `changed_data`** to the one-liner from the ticket:
  `return [name for name, bf in self._bound_items() if bf._has_changed()]`.
  It still returns a list of field names, preserving the public contract relied on by
  `django/contrib/auth/forms.py` (`SetPasswordForm.changed_data`) and
  `django/contrib/admin/utils.py`.

### `django/forms/boundfield.py`

- **Added `BoundField._has_changed()`**, which contains the per-field logic moved out of
  `changed_data` verbatim (show-hidden-initial handling, `to_python`/`ValidationError`
  "assume changed", otherwise compare `self.initial` vs `self.data` via
  `field.has_changed()`). This places the "did the data change?" decision on the object
  that actually owns the bound data.
- **Added `from django.core.exceptions import ValidationError`** for the
  show-hidden-initial branch.

No other call sites needed updates: `_field_data_value`/`_widget_data_value`/
`get_initial_for_field` remain and are still used (via `BoundField.data`/`.initial` and
`_has_changed`). No subclass overrides `_clean_fields`, and the only `changed_data`
override (auth) just calls `super()` and treats the result as a name list.

## Behavioural effect (intended)

For a disabled `DateTimeField`/`TimeField` with a microsecond-bearing or callable
`initial`, `form.cleaned_data[name]` now equals `form[name].initial`. This matches the
adjusted `test_datetime_clean_initial_callable_disabled` described in the ticket
(`initial=datetime.datetime.now, disabled=True` → `form.cleaned_data['dt'] ==
form['dt'].initial`). `has_changed()`/`changed_data` are unchanged for disabled fields
(`Field.has_changed` still short-circuits to `False`), so
`test_datetime_changed_data_callable_with_microseconds` still yields `[]`.

## Assumptions / alternatives considered

- **Method name `_has_changed`.** The ticket prose says it "could be called *something
  like* `bf.did_change()`" (explicitly tentative) while its code sketch writes
  `bf._did_change()`. Since this is a private helper exercised only through the public
  `changed_data`/`has_changed`/`cleaned_data` (behaviour), the exact spelling is not
  observable by callers. I chose `_has_changed` because it mirrors the
  `Field.has_changed(initial, data)` it delegates to, keeping the wrapper/delegate names
  aligned. If a reviewer prefers strict fidelity to the sketch, rename both occurrences
  to `_did_change`.
- **Only fixing the disabled branch in place** (e.g. swapping the single
  `get_initial_for_field` call for `self[name].initial`) was considered and rejected: it
  fixes the symptom but not the "reduce the number of code paths" goal of the ticket and
  leaves `changed_data`/`_clean_fields` deriving values independently of `BoundField`.
- **`bf.data` vs re-deriving via `_field_data_value`.** Using `bf.data` is identical to
  the previous expression but routes through the BoundField, which is the whole point of
  the change; the prefixing (`html_name`) is already baked into the BoundField.
