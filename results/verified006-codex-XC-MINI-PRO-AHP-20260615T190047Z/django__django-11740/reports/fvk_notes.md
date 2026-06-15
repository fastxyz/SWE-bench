# FVK Notes

## Decision Summary

V1 stands unchanged. The audit found that the source change in
`repo/django/db/migrations/autodetector.py` satisfies the public intent for
django__django-11740 and no additional source edit is justified.

## Trace to Findings and Proof Obligations

### Kept the V1 source change

Decision: keep the added dependency collection in `generate_altered_fields()`.

Reasoning: FINDINGS F1 identifies the original bug as an `AlterField` operation
missing target-app dependency metadata after a scalar-to-FK change. PROOF
OBLIGATIONS PO1 and PO2 require the altered-field path to attach
`_get_dependencies_for_foreign_key(field)` to the generated `AlterField`, and
PO3 shows that `_build_migration_list()` converts that auto-dependency into a
real migration dependency. V1 does exactly that.

### Kept the broader relational condition

Decision: do not narrow the fix to only `new relation and old non-relation`.

Reasoning: FINDINGS F2 records that the dependency invariant belongs to the new
emitted relational target, not only to the specific UUID-to-FK transition from
the issue. PO1 covers all in-scope relational emitted fields, PO2 requires reuse
of the existing helper, and PO4 preserves scalar non-relation behavior. This
means V1's broader guard is justified and does not create an unrelated scalar
behavior change.

### Made no additional source edits

Decision: leave `repo/django/db/migrations/autodetector.py` unchanged during the
FVK pass.

Reasoning: PO5 confirms the concrete-to-M2M and M2M-to-concrete remove/add path
is unchanged. PO6 confirms public compatibility: no signature, operation type,
or operation constructor shape changed. With F1 resolved and F2 confirming the
scope of the relation guard, there was no remaining source-level finding to
repair.

### Did not edit or run tests

Decision: no test files were changed and no test commands were run.

Reasoning: FINDINGS F3 and F4 record the environment and task constraints. PO7
requires compliance with the no-execution and no-test-edit rules. The future
test recommendation is documented in `fvk/ITERATION_GUIDANCE.md` instead.

### Did not run K tooling

Decision: keep the FVK proof labeled "constructed, not machine-checked."

Reasoning: FINDINGS F3 and PO7 require writing commands and reasoning about the
expected result rather than running `kompile`, `kast`, or `kprove`. The commands
are recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.
