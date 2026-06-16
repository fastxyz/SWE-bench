# Specification

Status: constructed, not machine-checked.

## Target

Target source: `repo/django/forms/formsets.py`, `BaseFormSet.non_form_errors()`
and `BaseFormSet.full_clean()`.

Target observable: the `ErrorList` returned by `formset.non_form_errors()` and
the CSS class string that `ErrorList.as_ul()` renders from its `error_class`
attribute.

## Human-readable contract

For every formset-level non-form error list produced by `BaseFormSet`, the
`ErrorList` must be constructed with the extra error class `nonform`.

This must hold for:

- an unbound formset, which returns an empty non-form error list,
- a bound formset with no non-form errors,
- a bound formset with a management-form error appended to `_non_form_errors`,
- a bound formset whose formset-wide validation raises `ValidationError`.

The contract preserves:

- the existing `ErrorList` return type,
- the existing error messages and list contents,
- field-error and form non-field-error behavior outside
  `formset.non_form_errors()`,
- existing public call sites that render or iterate the returned `ErrorList`.

## Intent ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries mirrored into
`fvk/formset-nonform-spec.k`:

- E1: add `nonform` CSS class for formset non-form errors,
- E2: mirror the existing form `nonfield` convention,
- E3: expose the signal to custom `ErrorList` constructors,
- E4: document the behavior,
- E6: treat old tests expecting no `nonform` as suspect legacy evidence.

## Formal model

The formal core is a property-complete abstraction, not a full Django/Python
semantics:

- `fvk/mini-django-errorlist.k` models the relevant values: validation outcome
  paths, error contents, `ErrorList` construction, and rendered class strings.
- `fvk/formset-nonform-spec.k` states claims that all in-scope
  `non_form_errors()` outcomes produce an `ErrorList` whose rendered class is
  `errorlist nonform`, while preserving the expected error contents.

The abstraction is sufficient for this issue because it distinguishes a
passing candidate (`extraClass == nonform`) from the pre-fix failing candidate
(`extraClass == noExtra`) on the exact property under test.

## Preconditions and frame conditions

Precondition: the formset uses an `error_class` callable compatible with
Django's `ErrorList` constructor protocol, including the `error_class` keyword.
This is a public API compatibility assumption already required by form
non-field errors.

Frame conditions:

- no change to validation rules or error message selection,
- no change to `ErrorList.__init__()` or rendering behavior,
- no change to `Form.non_field_errors()` or field error construction,
- no test files modified.

## Out-of-scope observation

`repo/django/forms/models.py` has direct assignments to a form's
`NON_FIELD_ERRORS` in model formset uniqueness checks. Those are per-form
non-field errors, not `formset.non_form_errors()`. They are not part of this
issue's requested `nonform` formset-level contract, so this FVK pass does not
use them to justify an additional source change.
