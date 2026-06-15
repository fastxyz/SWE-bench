# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep V1 source unchanged.

The FVK audit found that V1 satisfies the intent-derived obligations:

- F1 / PO1-PO8 confirm the core validators now expose `value`.
- F2 / PO4-PO5 confirm validators with derived internal values still expose
  the original submitted value.
- F3 / PO9 confirms the postgres `KeysValidator` direct errors are covered.
- F4 / PO10 rejects expanding the patch into password validators or field
  cleaners without explicit public intent and security review.

## Recommended Future Tests

Do not edit tests in this task. Future public tests should cover representative
invalid paths:

- `EmailValidator(message='Email "%(value)s" is invalid.')('blah')`
- `URLValidator(message='URL "%(value)s" is invalid.')('http://bad_domain')`
- `RegexValidator('x', message='bad %(value)s')('y')`
- `DecimalValidator(...).messages[...]` customized to include `%(value)s`
- `FileExtensionValidator(..., message='bad %(value)s %(extension)s')`
- `KeysValidator(..., messages={'missing_keys': 'bad %(value)s %(keys)s'})`

Each test should inspect the raised `ValidationError` object's `params` and
rendered message.

## Machine-Check Guidance

The formal artifacts are intentionally not executed here. In an environment
with K available, run:

```sh
kompile fvk/mini-validator.k --backend haskell
kast --backend haskell fvk/validators-spec.k
kprove fvk/validators-spec.k
```

Keep all existing tests until the proof has been machine-checked and ordinary
Django tests have also passed.

## Next Iteration Risks

If product intent later expands "validators" to include password validators,
ask the explicit security question from F4 before adding `params['value']` to
password-validation errors.

If product intent expands to all form/model field cleaning errors, that is a
larger API change than this issue describes. Run a separate compatibility audit
because many field errors are not reusable validator callables and some already
have specialized params.
