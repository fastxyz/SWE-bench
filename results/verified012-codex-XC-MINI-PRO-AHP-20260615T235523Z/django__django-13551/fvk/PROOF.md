# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were run.

## Artifacts

- Semantics fragment: `fvk/mini-python-token.k`
- Claims: `fvk/password-reset-token-spec.k`
- Intent and adequacy audit: `fvk/INTENT_SPEC.md`,
  `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`,
  `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

## Commands to run later

These commands are recorded for a future environment with K installed:

```sh
kompile fvk/mini-python-token.k --backend haskell
kast --backend haskell fvk/password-reset-token-spec.k
kprove fvk/password-reset-token-spec.k
```

Expected machine-check result after successful proof discharge: `#Top`.

## Trusted abstraction

The K model represents `salted_hmac(...).hexdigest()[::2]` as an abstract digest
constructor over the modeled hash input. The proof assumes constructor
distinction: different modeled hash inputs produce different modeled digest
terms. This is the normal software-level abstraction of Django's existing HMAC
token design; real cryptographic collision resistance remains part of the
trusted base.

## Proof sketch

PO1 follows by symbolic execution of `makeHashValue(USER, T)`. The semantics
rewrites it to `hashValue(USER, T)`, and `hashValue()` constructs
`hashInput(PK, PASSWORD, LOGIN, T, emailComponent(USER))`. For a configured
field containing `email(EMAIL)`, `emailComponent()` rewrites to `EMAIL`.

PO2 follows by one rewrite of `checkToken(USER, token(T,
digest(hashValue(USER, T))), NOW, TIMEOUT)`. Under the precondition
`NOW - T <= TIMEOUT`, the digest equality is reflexive and the timeout
comparison is true, so the result is `true`.

PO3 follows from the same rewrite with two user states. The old token contains
`digest(hashValue(U_old, T))`. The check against `U_new` recomputes
`digest(hashValue(U_new, T))`. The two `hashValue()` terms differ only in their
email component, and the claim requires `OLD_EMAIL != NEW_EMAIL`, so the digest
terms are distinct in the model and the equality is false. With the token still
unexpired, `false and true` rewrites to `false`.

PO4 follows from the `emailComponent()` rules for `missingFields()` and
`nullEmail()`, both of which rewrite to the empty string. This models V1's
`getattr(user, email_field, '') or ''` fallback.

PO5 is covered by the same `emailComponent()` rule as PO1. The rule matches the
field whose name equals the configured field name, modeling
`get_email_field_name()` rather than a hard-coded `email` attribute.

PO6 is a frame proof over untouched source branches. V1 only changes the data
returned by `_make_hash_value()`. It does not change token parsing,
`constant_time_compare()`, timeout comparison, secret selection, legacy
algorithm handling, password inclusion, or last-login inclusion.

PO7 is discharged by the compatibility audit: signatures and call shapes are
unchanged, and no in-tree override of `_make_hash_value()` exists.

## No loops or circularities

The audited token code has no loops. The proof does not require a circularity
claim; all proof steps are straight-line symbolic execution plus constructor
disequality and frame reasoning.

## Test guidance

No tests were modified. Because the proof is not machine-checked, no test is
recommended for deletion. Useful tests to add in a normal development setting
would cover:

- token rejection after the configured email value changes;
- rejection for custom `EMAIL_FIELD` changes;
- token generation for a custom `AbstractBaseUser` subclass without a concrete
  email attribute.
