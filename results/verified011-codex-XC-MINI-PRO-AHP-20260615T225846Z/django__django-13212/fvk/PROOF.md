# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## What Is Proved

For the audited reusable built-in validators, every invalid in-domain
validation path that raises `ValidationError` includes the original submitted
value in `error.params['value']`. Existing success behavior, messages, codes,
and specialized params are preserved.

The constructed K-style core is:

- `fvk/mini-validator.k`
- `fvk/validators-spec.k`

## Claim Shape

The model treats each validator's validity decision as an abstract predicate:

`isInvalid(VALIDATOR, VALUE)`

This is adequate because the issue does not change what values are valid. It
changes the error payload on invalid paths.

The key reachability claim is:

```k
claim
  <k> validate(VALIDATOR:Validator, VALUE:Value)
      => error(messageOf(VALIDATOR), codeOf(VALIDATOR),
               withValue(baseParams(VALIDATOR, VALUE), VALUE)) ... </k>
  requires isInvalid(VALIDATOR, VALUE)
  [all-path]
```

Paraphrase: on every invalid validator path, validation reaches an error
outcome whose params are the previous validator-specific params updated with
`value -> original submitted value`.

## Constructed Proof

1. Start from any validator `VALIDATOR` and submitted value `VALUE` satisfying
   `isInvalid(VALIDATOR, VALUE)`.
2. By the `MINI-VALIDATOR` invalid rule, `validate(VALIDATOR, VALUE)` rewrites
   to `error(messageOf(VALIDATOR), codeOf(VALIDATOR),
   withValue(baseParams(VALIDATOR, VALUE), VALUE))`.
3. By the `withValue` rule, the params map is the base params map updated at
   key `value` with `VALUE`.
4. Source inspection maps every patched invalid branch to that rule:
   `RegexValidator`, `URLValidator`, `EmailValidator`, IP validators,
   `DecimalValidator`, `FileExtensionValidator`, `ProhibitNullCharactersValidator`,
   and `KeysValidator` either pass `params={'value': value}` directly or merge
   `value` into existing params.
5. `BaseValidator` already matched the same rule before V1, so derived
   validators remain covered without further code changes.
6. No loop or recursion circularity is needed; the audited property is a
   straight-line invalid-branch postcondition.

## Proof Obligations Discharged

Discharged obligations: PO1 through PO11 in
`fvk/PROOF_OBLIGATIONS.md`.

Proof-derived findings: F1 through F5 in `fvk/FINDINGS.md`.

## Residual Risk

This proof is constructed over a mini semantics, not machine-checked against
real Python semantics. It proves the changed observable property, not the
correctness of Django's validator algorithms. Test removal is not recommended.

## Commands To Reproduce The Machine Check Later

These commands are recorded for a future environment and were not executed:

```sh
kompile fvk/mini-validator.k --backend haskell
kast --backend haskell fvk/validators-spec.k
kprove fvk/validators-spec.k
```

Expected machine-check outcome in a future K environment: the claims discharge
to `#Top`.
