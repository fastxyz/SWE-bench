# Iteration Guidance

## Decision

V1 should not stand unchanged. FVK found one completeness gap: the explicit
widget path was fixed, but an effective `RadioSelect` supplied by a custom form
field class default still kept the generated blank label. V2 addresses this by
checking the form class default widget when no explicit widget is supplied.

## Source Change To Keep

Keep the V2 source change in
`repo/django/db/models/fields/related.py::ForeignKey.formfield()`:

- read `kwargs['widget']` if supplied;
- otherwise read the selected form field class's default `widget`;
- set `empty_label=None` only for non-blank effective `RadioSelect` widgets when
  no explicit `empty_label` was supplied.

This discharges FVK-F1 and PO7 while preserving PO4, PO5, PO6, and PO8.

## Suggested Tests For Maintainers

Do not edit tests in this benchmark task. Maintainers should keep or add tests
for:

- `Meta.widgets = {'fk': forms.RadioSelect()}` with `blank=False`;
- `Meta.widgets = {'fk': forms.RadioSelect}` with `blank=False`;
- a custom `ModelChoiceField` subclass with `widget = forms.RadioSelect` passed
  through `field_classes`;
- `blank=True` radio foreign keys still including an empty choice;
- default `Select` foreign keys preserving the blank option;
- explicit `empty_label` remaining an override.

## Residual Risk

The proof is constructed, not machine-checked. No tests or project code were
run, by task instruction. Keep the Django test suite intact and treat the K
commands in `fvk/PROOF.md` as future verification steps, not completed evidence.
