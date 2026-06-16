# FVK Spec

Status: constructed, not machine-checked.

## Target

`repo/django/forms/models.py`

- `ModelChoiceField.default_error_messages['invalid_choice']`
- `ModelChoiceField.to_python()`

No loops are present in the audited function.

## Public intent ledger

The public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical
entries are:

- E-001: invalid-choice errors must expose the rejected value.
- E-002: `ModelChoiceField` should match `ChoiceField` and other choice fields.
- E-003: the required fix has two parts: pass params and change the default
  message.
- E-006: valid and empty behavior should be preserved.
- E-007: tests or examples asserting the old default message are suspect legacy
  evidence.

## Formal contract

The K artifacts are:

- `fvk/mini-django-forms.k`
- `fvk/model-choice-field-spec.k`

The model abstracts a queryset as a map from lookup key to object and models
`ModelChoiceField.to_python()` as an outcome-producing computation:

- empty value -> `ok(emptyValue())`;
- submitted key present in queryset -> `ok(object)`;
- correct-model instance -> convert to the same lookup key before lookup;
- submitted key absent from queryset -> `validationError("invalid_choice", ..., params)`;
- type/conversion failure -> the same invalid-choice error path.

## Required postconditions

1. Empty values return `None`/empty without raising `invalid_choice`.
2. Valid submitted keys return the queryset object and do not change success
   behavior.
3. Invalid submitted keys raise `ValidationError` with code `invalid_choice`.
4. Invalid submitted keys include `params['value']` equal to the submitted value.
5. Invalid model-instance keys include `params['value']` equal to the lookup key
   used by `queryset.get()`.
6. Invalid conversion/type failures include `params['value']` equal to the value
   that failed conversion or lookup.
7. The default invalid-choice message contains `%(value)s`.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the K claims. `fvk/SPEC_AUDIT.md`
compares that paraphrase to the intent spec and marks every required runtime
behavior as `pass`.

