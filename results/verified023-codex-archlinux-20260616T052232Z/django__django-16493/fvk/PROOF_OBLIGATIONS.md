# PROOF OBLIGATIONS

Status: constructed for audit; not machine-checked.

## O1 - Intent adequacy

Statement: The formal claims must express the public issue and docs, not merely
the V1 implementation.

Evidence: E1-E9.

Discharge: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`
align all five formal claims with public intent. No claim is candidate-derived
without public support.

Status: discharged by audit.

## O2 - Callable returning default_storage is serialized as callable

Statement: For a field built from a callable storage provider whose evaluated
storage is `default_storage`, deconstruction includes the original callable in
the `storage` kwarg.

Evidence: E1-E6.

Formal claim: `CALLABLE-DEFAULT`.

V1 code obligation: `getattr(self, "_storage_callable", self.storage)` must be
used before comparing with `default_storage`, and the selected value must be
assigned to `kwargs["storage"]`.

Status: discharged by V1.

## O3 - Implicit/default storage omission is preserved

Statement: A field with no explicit storage argument, or with direct
`default_storage`, omits `storage` from deconstruction.

Evidence: E7-E8.

Formal claims: `DEFAULT-IMPLICIT`, `DIRECT-DEFAULT`.

Status: discharged by V1.

## O4 - Direct non-default storage is serialized as storage object

Statement: A field built from a direct non-default storage object includes that
object in the `storage` kwarg.

Evidence: E7-E8.

Formal claim: `DIRECT-OTHER`.

Status: discharged by V1.

## O5 - Callable non-default storage is serialized as original callable

Statement: A field built from a callable storage provider whose evaluated
storage is non-default includes the original callable in the `storage` kwarg.

Evidence: E7-E9.

Formal claim: `CALLABLE-OTHER`.

Status: discharged by V1.

## O6 - Public compatibility is preserved

Statement: The fix must not alter public signatures or deconstruction tuple
shape, and must not require public callsite or override updates.

Evidence: E7-E9 plus source inspection of `ImageField.deconstruct()`.

Discharge: `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by audit.

## O7 - Honesty constraints

Statement: No tests, Python execution, or K tooling may be run; emitted proof
commands must be recorded but not executed.

Evidence: user instructions.

Discharge: Commands are listed in `PROOF.md` only. No tests or code execution
were attempted.

Status: discharged by process.
