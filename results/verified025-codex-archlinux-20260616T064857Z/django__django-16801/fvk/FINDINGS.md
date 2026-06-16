# FINDINGS

Status: constructed, not machine-checked.

## F1: V1 fixes the reported no-op receiver registration

- Classification: code bug, resolved by V1.
- Input/state: concrete model, `ImageField(width_field=None,
  height_field=None)`.
- Observed before V1: `contribute_to_class()` connected
  `update_dimension_fields()` to `post_init`; each model initialization paid
  signal dispatch, and the receiver returned immediately because no dimension
  fields existed.
- Expected: no receiver is registered for this field shape.
- Evidence: `SPEC.md` E1, E2, E3.
- Proof obligations: PO1 and PO6.
- V1 status: resolved by adding `(self.width_field or self.height_field)` to
  the connection guard.

## F2: V1 preserves required registration for dimension fields

- Classification: regression check, no code bug found.
- Input/state: concrete model with width only, height only, or both dimension
  fields configured.
- Expected: `post_init` receiver remains registered so constructor-time
  dimension updates still occur.
- Evidence: `SPEC.md` E4 and E8.
- Proof obligations: PO2, PO3, PO4.
- V1 status: confirmed. The new disjunct is true whenever either dimension
  field is configured.

## F3: V1 preserves abstract-model behavior

- Classification: regression check, no code bug found.
- Input/state: abstract model with any `ImageField` dimension configuration.
- Expected: no direct receiver registration on the abstract class.
- Evidence: `SPEC.md` E5.
- Proof obligations: PO5.
- V1 status: confirmed. The pre-existing `not cls._meta.abstract` guard remains
  required and unchanged.

## F4: Assignment-time updates are outside the removed receiver path

- Classification: regression check, no code bug found.
- Input/state: assigning an image after `Model.__init__()` when a previous file
  value exists.
- Expected: `ImageFileDescriptor.__set__()` still forces
  `update_dimension_fields(instance, force=True)`.
- Evidence: `SPEC.md` E6.
- Proof obligations: PO7.
- V1 status: confirmed. V1 does not edit `ImageFileDescriptor.__set__()`.

## F5: No public compatibility break found

- Classification: compatibility check, no code bug found.
- Input/state: public uses of `ImageField`, `width_field`, `height_field`,
  descriptors, and signal registration for dimension-bearing fields.
- Expected: public API shape remains unchanged.
- Evidence: `SPEC.md` compatibility audit.
- Proof obligations: PO8.
- V1 status: confirmed. The only behavior removed is the no-op receiver that the
  prompt identifies as unnecessary.

## F6: Proof and tests remain unexecuted by constraint

- Classification: proof capability / execution constraint.
- Input/state: this benchmark turn.
- Observed: Python tests and K commands are forbidden.
- Expected: no test deletion, no claim of machine-checked proof.
- Evidence: user task and FVK honesty gate.
- Proof obligations: PO9.
- V1 status: acceptable. The proof is constructed only, and tests were not run.

## Overall Finding

No unresolved code findings remain after the FVK audit. V1 stands unchanged.
