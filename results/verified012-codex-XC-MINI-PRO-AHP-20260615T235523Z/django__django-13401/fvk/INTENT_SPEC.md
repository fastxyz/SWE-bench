# Intent Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Public Intent Obligations

I1. Abstract model field copies attached to different concrete models must not
compare equal.

Evidence: `benchmark/PROBLEM.md` says "Abstract model field should not be
equal across models" and "if the field.model is different, they will compare
unequal."

I2. A set containing same-named fields copied from the same abstract base onto
different concrete models must retain both fields.

Evidence: the issue reports
`len({B._meta.get_field('myfield'), C._meta.get_field('myfield')}) == 1` as
the surprising/broken behavior.

I3. Hashing must be consistent with the new equality relation.

Evidence: the issue says "Similarly, it is probably wise to adjust __hash__."

I4. Field ordering must remain creation-counter-primary, with the model used
only to break equal-counter collisions.

Evidence: the issue says "__lt__" should be adjusted "to match" and warns that
ordering by model first broke an existing test; it specifically suggests
ordering first by `self.creation_counter`.

I5. Abstract-field copying should preserve declaration-order semantics.

Evidence: the problem identifies equality over `creation_counter` as the root
cause, not abstract inheritance copying. Existing source comments in
`Options.add_field()` state fields are inserted by `creation_counter`.

I6. Public method shape should remain compatible.

Evidence: the issue requests semantic changes to `__eq__`, `__hash__`, and
`__lt__`, not signature changes or new public APIs.
