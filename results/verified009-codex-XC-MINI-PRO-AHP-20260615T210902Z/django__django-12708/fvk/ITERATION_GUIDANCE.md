# ITERATION GUIDANCE

Status: V1 stands for the verified crash fix.

## Keep V1 source unchanged

Findings F1 and F3 are discharged by Proof Obligations PO1-PO4. The V1 patch is
minimal, targets the source of the wrong-count crash, and preserves public
compatibility.

## Do not broaden this patch to migration optimizer churn

Finding F2 and PO5 identify a real but separate design concern: avoiding physical
index recreation when migrating from `index_together` to `Meta.indexes`. A safe
fix needs explicit semantics for database index names and migration state. It
should not be guessed in this repair pass.

## Recommended public tests for a normal development environment

Do not add tests in this benchmark workspace. In a normal Django development
environment, add tests that exercise:

- removing `index_together` while same-field `unique_together` remains;
- both introspection orders, unique object before index and index before unique;
- preserving the existing error when there is no non-unique matching index or
  more than one non-unique matching index;
- unchanged `alter_unique_together()` behavior.

## Machine-check follow-up

Run the commands listed in `PROOF.md` in an environment with K installed. Treat
test-redundancy recommendations as conditional until `kprove` returns `#Top`.
