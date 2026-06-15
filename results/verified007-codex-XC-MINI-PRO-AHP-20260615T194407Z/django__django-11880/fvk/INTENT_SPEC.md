# Intent Specification

Constructed before accepting candidate behavior as the specification.

## Required behavior

I1. `Field.__deepcopy__()` must produce a copied field whose
`error_messages` mapping is independent from the source field's mapping.
Top-level mutation of one copied field's `error_messages` must not affect the
source field or any independently copied field.

I2. The independence requirement includes nested mutable values in the
`error_messages` mapping. The issue states that modification of "the error
message itself" must not leak between copied fields, so a shallow dictionary
copy is not sufficient.

I3. The copied field must preserve the configured error message contents. The
fix should isolate state without rebuilding defaults or discarding runtime
customizations.

I4. Form instances rely on `copy.deepcopy(self.base_fields)` to isolate
`self.fields` from class-wide `base_fields`. Therefore the field-level copy
contract must hold when form instances are constructed, not only when
`Field.__deepcopy__()` is called directly.

I5. Existing public method shape must remain compatible:
`Field.__deepcopy__(self, memo)` must keep the same signature and return a
field object with the existing widget and validator-copy behavior preserved.

## Out of scope

Termination is not a separate concern for this method because there is no loop
in the modeled code. The proof is partial correctness and constructed, not
machine-checked.
