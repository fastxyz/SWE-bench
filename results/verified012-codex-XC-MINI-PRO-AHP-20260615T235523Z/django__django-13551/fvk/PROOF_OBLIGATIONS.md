# Proof Obligations

Status: constructed, not machine-checked. Each obligation maps to findings in
`fvk/FINDINGS.md` and claims in `fvk/password-reset-token-spec.k`.

## PO1 - Email is part of the hash input

For every in-domain user and timestamp, `_make_hash_value(user, timestamp)`
contains the configured email component after primary key, password,
last-login timestamp, and token timestamp.

Evidence: E1, E2, E4, E5.

Findings: F1, F2, F5.

K claims: `HASH-USES-CONFIGURED-EMAIL`.

Status: discharged by V1 source inspection and constructed K claim.

## PO2 - Same-state generated tokens validate

For an unexpired token generated from user state `U` at timestamp `T`,
checking the token against the same state `U` with the same secret and algorithm
returns `True`.

Evidence: E6, E7.

Findings: none open.

K claims: `SAME-STATE-VALIDATES`.

Status: discharged as a frame condition over existing behavior.

## PO3 - Concrete email changes reject old tokens

For an unexpired token generated from `U_old`, checking against `U_new` returns
`False` when all modeled state is equal except:

`email_component(U_old) != email_component(U_new)`.

Evidence: E1, E2.

Findings: F1, F5.

K claims: `EMAIL-CHANGE-REJECTED`.

Status: discharged by V1 because the two recomputed HMAC inputs differ in the
email component.

## PO4 - Missing or null-like email remains defined

When the configured email field is absent or null-like, `_make_hash_value()`
uses `""` as the email component and does not raise due solely to missing email.

Evidence: E3.

Findings: F3, F4.

K claims: `MISSING-EMAIL-DEFINED`, `NULL-EMAIL-DEFINED`.

Status: discharged by `getattr(user, email_field, '') or ''`.

## PO5 - Custom `EMAIL_FIELD` is honored

The selected email component comes from `user.get_email_field_name()`, so custom
user models can use fields such as `email_address`.

Evidence: E4, E5.

Findings: F2.

K claims: `HASH-USES-CONFIGURED-EMAIL`.

Status: discharged by V1 source inspection.

## PO6 - Existing token invalidators and guards are preserved

Password hash, last-login timestamp, token timestamp, secret, algorithm, timeout
comparison, malformed-token parsing, and absent-user checks keep their existing
roles.

Evidence: E6, E7.

Findings: none open.

K claims: `PASSWORD-CHANGE-REJECTED`, `EXPIRED-TOKEN-REJECTED`, plus source
frame inspection for branches outside the email-focused model.

Status: discharged as frame conditions; V1 only appends email to the hash input.

## PO7 - Public compatibility is preserved

No public method signature, callsite shape, or in-tree subclass override is
broken by the change.

Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Findings: none open.

K claims: not applicable; this is a source compatibility obligation.

Status: discharged by source inspection.

## PO8 - Honesty gate

The proof remains labeled constructed, not machine-checked, and no test removal
is claimed without future K execution.

Evidence: FVK `verify.md` honesty gate and this session's no-execution
constraint.

Findings: F6.

K claims: all.

Status: discharged by artifact labeling and by not running tools.
