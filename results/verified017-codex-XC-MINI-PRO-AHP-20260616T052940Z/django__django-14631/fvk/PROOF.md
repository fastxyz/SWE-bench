# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Adequacy Gate

The intent in `SPEC.md` is derived from the public issue, not from V1 behavior:

- the source of `_clean_fields()` values must be `BoundField`;
- disabled callable initials must use the same cached initial seen at
  `form[name].initial`;
- per-field `changed_data` logic belongs on `BoundField`;
- existing field cleaning, hidden-initial conversion, and validation behavior
  are frame conditions.

The abstract claim in `django-forms-spec.k` states exactly this observable:
cleaned values and changed-data names are functions of the bound fields for the
form's ordered field list. It does not prove unrelated Django behavior.

## Proof Sketch

P1. `_bound_items()` establishes the bound-field sequence.

By PO1, `self[name]` returns the cached `BoundField` for a field name. By PO2,
`_bound_items()` yields `(name, self[name])` for each field in order. Therefore
any consumer of `_bound_items()` receives the same bound field that templates
and `form[name]` use.

P2. `_clean_fields()` uses bound-field values.

Proceed by induction over the finite sequence from P1.

Base case: with no remaining fields, `_clean_fields()` has no further
observable cleaned-data updates.

Step case: for current `(name, bf)`, V1 binds `field = bf.field`.

- If `field.disabled`, PO4 gives `value = bf.initial`.
- Otherwise, PO3 gives `value = bf.data`.
- If `field` is a `FileField`, PO5 gives `field.clean(value, bf.initial)`.
- Otherwise, S2 gives `field.clean(value)`.

PO6 preserves assignment to `cleaned_data[name]`, the subsequent
`clean_<name>()` hook, and `ValidationError` handling. Thus each field's
cleaning path satisfies S2, and the induction composes over all fields.

P3. The issue-specific disabled callable case follows.

For a disabled `DateTimeField` with callable initial, P1 and P2 force the
cleaning input to be `bf.initial`. Existing `BoundField.initial` is a
`cached_property`; it evaluates the callable and applies the widget
microsecond-normalization path used for rendering. Therefore `_clean_fields()`
does not evaluate a separate callable initial for the same field. This
discharges PO10 and F1.

P4. `BoundField._has_changed()` preserves old per-field semantics.

Case split on `field.show_hidden_initial`.

- False branch: PO7 gives exactly `field.has_changed(bf.initial, bf.data)`,
  matching the old non-hidden branch of `BaseForm.changed_data`.
- True branch: PO8 gives the same hidden-widget read, `field.to_python()`
  conversion, `ValidationError` means changed, and final
  `field.has_changed(converted_initial, bf.data)` comparison as the old code.

Therefore `_has_changed()` satisfies S4 and F4.

P5. `changed_data` is the bound-field aggregation.

By PO9, `BaseForm.changed_data` returns field names from `_bound_items()` for
which `bf._has_changed()` is true. P1 supplies the correct ordered bound-field
sequence, and P4 supplies the correct per-field predicate. Therefore S3 is
proved.

P6. Compatibility frame.

PO11 shows V1 adds only private helpers and leaves public signatures unchanged.
F5 notes the only compatibility consideration: a custom external
`get_bound_field()` returning a non-compatible object would not have the new
private method. The in-repo API returns Django `BoundField`, and a fallback in
`BaseForm.changed_data` would recreate the duplicate code path the issue asks
to eliminate. No V2 source change follows from this residual note.

## Constructed K Artifacts

- `fvk/mini-django-forms.k`
- `fvk/django-forms-spec.k`

Commands recorded for later machine-checking, not executed in this benchmark:

```sh
kompile fvk/mini-django-forms.k --backend haskell
kast --backend haskell fvk/django-forms-spec.k
kprove fvk/django-forms-spec.k
```

Expected result after a faithful executable K encoding: `#Top`.

## Residual Risk

This proof is abstract and constructed, not machine-checked. It verifies the
source of form values and changed-data decisions, not the full semantics of
every Django `Field`, widget, or subclass outside the repository. Termination is
not separately proved, but the audited loops are finite iterations over
`self.fields`.

No test-redundancy recommendation is made: the benchmark forbids editing tests,
the relevant tests may be hidden, and the proof has not been machine-checked.
