# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: Invalid validator errors expose original value

For every reusable built-in validator in scope and every in-domain submitted
value `v`, if validation raises `ValidationError`, then
`error.params['value'] == v`.

Traces to findings: F1, F2, F3.

Status: discharged by source inspection and K claim `VALIDATORS-SPEC`.

## PO2: Valid inputs preserve existing behavior

For every validator in scope and every value that was valid before V1, the
validator still returns normally.

Reason: V1 only changes `raise ValidationError(...)` arguments on invalid
branches. No validity predicate, regex, parsing rule, limit comparison, or
return path was changed.

Status: discharged by diff inspection.

## PO3: EmailValidator uses full submitted email as value

Every direct invalid raise in `EmailValidator.__call__()` passes params built
before splitting user/domain parts: `{'value': value}`.

Status: discharged by source inspection.

## PO4: URLValidator uses original URL after punycode retry

If original URL regex validation fails, the validator may retry with a
punycoded URL. If the retry also fails, the raised error must use the original
submitted URL in `params['value']`.

Status: discharged by V1 catch/re-raise around `super().__call__(url)`.

## PO5: Derived helper failures are re-raised with top-level value

If URL IPv6 literal validation or Email domain-literal validation detects an
invalid helper value, the public validator's final `ValidationError` must
carry the top-level submitted URL/email, not the helper fragment.

Status: discharged for URL by catch/re-raise with URL params; discharged for
Email because helper errors are swallowed and final direct raise uses email
params.

## PO6: BaseValidator-derived validators already satisfy the obligation

`BaseValidator.__call__()` includes
`{'limit_value': limit_value, 'show_value': cleaned, 'value': value}`.
Therefore max/min value/length validators and postgres range/array validators
inherit the required value param.

Status: discharged by source inspection.

## PO7: DecimalValidator preserves max params and adds value

For decimal digit-count failures, `params['max']` must remain available and
`params['value']` must be added. For non-finite-number failures, `params` must
contain `value` without changing the legacy absent error code.

Status: discharged by source inspection.

## PO8: FileExtensionValidator preserves extension params and adds value

For invalid file extensions, `params['extension']` and
`params['allowed_extensions']` must remain available, and `params['value']`
must be added.

Status: discharged by source inspection.

## PO9: KeysValidator preserves keys params and adds value

For missing-key and extra-key errors, `params['keys']` must remain available
and `params['value']` must be added.

Status: discharged by source inspection.

## PO10: Scope boundary for field cleaners and password validators

The fix must not widen into field-cleaning errors or password-value exposure
without public intent evidence. Field/model cleaning errors are not the
reusable validator callable family named by the docs, and password validators
raise a security concern not present in the issue.

Status: discharged as a scope/compatibility constraint.

## PO11: Honesty gate

No tests, Python, or K commands may be run in this task. Proof and test
redundancy statements must be labeled constructed, not machine-checked.

Status: discharged by artifact labeling and by not running execution commands.

## Exact Commands To Machine-Check Later

These commands were not executed:

```sh
kompile fvk/mini-validator.k --backend haskell
kast --backend haskell fvk/validators-spec.k
kprove fvk/validators-spec.k
```
