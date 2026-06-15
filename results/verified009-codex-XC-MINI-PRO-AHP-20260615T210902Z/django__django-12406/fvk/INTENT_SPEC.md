# Intent Specification

This intent spec is derived from public task inputs only: `benchmark/PROBLEM.md`,
the existing Django source under `repo/`, and the V1 notes in
`reports/baseline_notes.md`.

## Required Behavior

I1. For a `ModelForm` field generated from a `ForeignKey` whose model field has
`blank=False`, rendering that field with a `RadioSelect` widget must not include
an empty-value radio option.

I2. For a new unbound model form in the I1 case, no `RadioSelect` input should be
checked merely because the model instance value is empty.

I3. Ordinary `Select` widgets must keep Django's existing blank-option behavior
for required fields. The issue explicitly calls that behavior idiomatic.

I4. When the model field has `blank=True`, a blank value is a valid model-form
selection, so radio widgets may still expose an empty choice.

I5. Explicit caller-supplied `empty_label` values are treated as intentional
overrides of the generated default. This follows Django's local convention that
`formfield()` keyword arguments override field-derived defaults.

I6. The public `ForeignKey.formfield()` signature and unrelated keyword behavior
must remain compatible. Queryset selection, `to_field_name`, labels, help text,
and other form-field defaults are out of the defect and must be preserved.

## Domain

The audited unit is the `ForeignKey.formfield()` defaulting decision that chooses
whether to pass `empty_label=None` to `ModelChoiceField`. The domain includes:

- explicit `widget` arguments that are `RadioSelect` classes, instances, or
  subclasses;
- the effective widget supplied by a custom form field class when no explicit
  `widget` argument is present;
- non-radio widgets, including Django's default `Select`;
- `blank=True` and `blank=False`;
- absent and explicit `empty_label` keyword arguments.

The proof is partial correctness over this defaulting decision and the resulting
`ModelChoiceField.empty_label` observable. It does not prove database access,
queryset iteration, template rendering, or termination.
