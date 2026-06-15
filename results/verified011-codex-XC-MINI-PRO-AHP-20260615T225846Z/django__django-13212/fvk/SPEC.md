# FVK Spec: django__django-13212

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Intent Specification

The public issue requires Django's built-in reusable validators to include the
submitted value in the `ValidationError` they raise, so custom messages can use
`%(value)s`.

The intended observable contract is:

1. For every in-domain call to a reusable built-in validator, if validation
   succeeds, existing success behavior is unchanged.
2. For every in-domain call to a reusable built-in validator, if validation
   fails by raising `ValidationError`, the raised error's `params` contains
   key `value` bound to the original submitted value.
3. Existing error `message`, `code`, and specialized params remain unchanged
   except for adding `value`.
4. For validators that validate a transformed or derived sub-value internally
   (URL punycode fallback, email domain/literal checks, IPv6 literal checks,
   file extension extraction, key-set checks), `value` means the original
   top-level submitted value, not the transformed helper value.
5. Field-level form/model cleaning errors and password validators are not in
   the repaired contract. The public issue and docs point to reusable validator
   callables, and password validators have a separate security-sensitive value
   exposure concern.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Make validators include the provided value in ValidationError" | Failed reusable validators must attach the provided input to `ValidationError.params`. | Encoded in PO1 and K claim `VALIDATORS-SPEC`. |
| E2 | prompt | "use a %(value)s placeholder" | The params key must be exactly `value`. | Encoded in PO1. |
| E3 | prompt | Example: invalid email value in custom message | `EmailValidator` is in scope and must preserve the full email input. | Encoded in PO3. |
| E4 | docs | `django.core.validators` contains callable validators for model/form fields | Core validators are the primary built-in family. | Encoded in PO1-PO8. |
| E5 | docs | Custom validator example passes `params={'value': value}` | The intended mechanism is Django's existing `ValidationError.params` interpolation. | Encoded in PO1. |
| E6 | docs | `django.contrib.postgres.validators` documents `KeysValidator` and range validators | Postgres reusable validators are public built-in validators; direct `KeysValidator` errors should include `value`; range/array inherit `BaseValidator`. | Encoded in PO9. |
| E7 | implementation | `BaseValidator` already had `{'limit_value', 'show_value', 'value'}` | Derived validators already satisfy the value-param obligation. | Confirmed in PO6. |
| E8 | implementation | V1 catches failed URL punycode retry and re-raises with original `params` | Prevents transformed ACE URL from replacing submitted URL in `value`. | Confirmed in PO4. |

## Formal Model

The formal core is in:

- `fvk/mini-validator.k`: a minimal validator-result semantics.
- `fvk/validators-spec.k`: K reachability claims for invalid validator calls.

The model abstracts each validator's validity predicate as
`isInvalid(validator, value)`. This is intentional: the issue is not changing
what is valid or invalid. The verified observable is the shape of the error
outcome on invalid paths.

Primary claim, paraphrased:

For any reusable built-in validator `VALIDATOR` and original submitted value
`VALUE`, if `isInvalid(VALIDATOR, VALUE)` holds, symbolic execution of
`validate(VALIDATOR, VALUE)` reaches a `ValidationError`-like outcome whose
params map is `baseParams(VALIDATOR, VALUE)` updated with `value -> VALUE`.

## Adequacy Audit

The K claim is neither weaker nor stronger than the public issue for the
audited property:

- It proves only invalid-path params, matching the `%(value)s` issue.
- It does not alter validity decisions, matching the minimal-change intent.
- It preserves `baseParams`, matching existing `max`, `extension`,
  `allowed_extensions`, and `keys` placeholders.
- It uses the original `VALUE`, matching the phrase "provided value".

The model is intentionally partial: it does not prove regex, URL, email,
decimal, IP, file, or key validity algorithms themselves. Those algorithms are
frame conditions, not the changed property.

## Public Compatibility Audit

No public function or method signatures changed. No new virtual-dispatch
arguments were introduced. `ValidationError` already accepts `params`; the
change only fills that existing argument. Existing callers that ignore
`params` continue to see the same messages and codes unless their custom
message explicitly references `%(value)s`, which is the requested behavior.

## Scope Decision

V1 is confirmed as the V2 source patch. The audit did not justify additional
source edits.
