# Intent Spec

Status: constructed from public intent before accepting candidate behavior.

## Public-intent obligations

I1. Formset non-form errors must be distinguishable from form field errors and
form non-field errors.

Evidence: `benchmark/PROBLEM.md` says, "in FormSets I'd expect to see the
nonform CSS class added for non form errors" and says this lets a custom
`ErrorList` distinguish "form field errors, non field errors (forms) and non
form errors (FormSets)."

I2. The class name to add is exactly `nonform`.

Evidence: the issue title is "Add `nonform` CSS class for non form errors in
FormSets" and the description repeats "add this nonform CSS class".

I3. The behavior should mirror the existing form non-field error convention.

Evidence: the issue says "Forms add the nonfield CSS class for non field
errors in ErrorList instances" and asks for similar treatment in formsets.

I4. The observable is the `ErrorList` returned by `formset.non_form_errors()`
and its rendered CSS class.

Evidence: the issue names "non form errors in FormSets"; Django's docs and
source expose this through `BaseFormSet.non_form_errors()`.

I5. Existing error content, validation flow, and public return type should be
preserved except for the additional CSS-class signal.

Evidence: the issue asks to add a CSS class and document it, not to change
validation rules, messages, or object type.

I6. Documentation should tell developers that formset non-form errors render
with the `nonform` class.

Evidence: the issue says "document it for developers to use."

## Domain

The in-scope domain is every `BaseFormSet.non_form_errors()` result produced by
`BaseFormSet.full_clean()`:

- an unbound formset with no errors,
- a bound formset with no non-form errors,
- a bound formset with management-form errors appended to `_non_form_errors`,
- a bound formset whose max/min/custom `clean()` validation raises
  `ValidationError` and replaces `_non_form_errors`.

The issue does not require changing per-form field errors or form non-field
errors; those are frame conditions.
