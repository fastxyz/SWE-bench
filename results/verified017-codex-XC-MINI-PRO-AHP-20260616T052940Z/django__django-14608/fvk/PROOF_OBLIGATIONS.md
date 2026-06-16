# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Initial non-form error list is tagged

For every `BaseFormSet.full_clean()` call, the initial `_non_form_errors`
object must be constructed as `self.error_class(error_class='nonform')`.

Evidence: required by intent entries I1-I4 and K claims C1-C3.

Discharge status: satisfied by `repo/django/forms/formsets.py`, where
`full_clean()` initializes `_non_form_errors` with `error_class='nonform'`.

## PO-2: Replacement non-form error list is tagged

When formset-wide validation raises `ValidationError`, the replacement
`_non_form_errors` object must be constructed as
`self.error_class(e.error_list, error_class='nonform')`.

Evidence: required by I1-I4 and K claim C4.

Discharge status: satisfied by `repo/django/forms/formsets.py` in the
`except ValidationError as e` branch.

## PO-3: Error contents are preserved

Adding the `nonform` CSS-class signal must not change whether the list is
empty or which error messages are included for management-form errors and
formset validation errors.

Evidence: frame condition I5 and K claims C1-C4, which keep the same
`Errors` value while changing only `ExtraClass`.

Discharge status: satisfied. V1 changes only the `error_class` constructor
argument and does not change append, validation, or message selection logic.

## PO-4: Public consumers keep the same value shape

`formset.non_form_errors()` must continue to return an `ErrorList`-compatible
object that supports rendering, iteration, truthiness, and membership checks.

Evidence: compatibility audit entries for admin templates, admin helpers, and
testing helpers.

Discharge status: satisfied. V1 continues using `self.error_class`, the same
factory as before and the same factory used by form errors.

## PO-5: Documentation states the new rendering class

The formset documentation must tell developers that non-form errors render
with `nonform`.

Evidence: intent entry I6.

Discharge status: satisfied by `repo/docs/topics/forms/formsets.txt`, which
adds an example rendering `<ul class="errorlist nonform">`.

## PO-6: Legacy no-class expectations do not veto the fix

Any public test or example expecting `formset.non_form_errors()` to render like
plain `ErrorList([...])` without `nonform` must be treated as suspect legacy
evidence when it conflicts with the issue.

Evidence: FVK suspect-evidence rule and ledger entry E6.

Discharge status: satisfied by recording FINDINGS.md F2 and not changing V1 to
preserve the legacy output.
