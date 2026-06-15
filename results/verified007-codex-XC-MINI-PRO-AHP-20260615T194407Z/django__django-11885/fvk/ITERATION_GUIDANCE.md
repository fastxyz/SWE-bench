# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit found no source-code defect against the public intent. Findings
F-1 and F-2 confirm the two public examples. Finding F-3 confirms the
parameter-limit guard is a required safety frame, not a missed optimization.
Finding F-4 records the only plausible ambiguity, distinct model classes sharing
one physical table, and rejects it as outside the public evidence for this issue.

## Next Code Change

No code change is recommended.

If future public evidence requires combining fast deletes across distinct model
classes sharing one physical table, do not stretch the existing `QuerySet.__or__`
path. That would need a lower-level SQL/DeleteQuery combiner with its own proof
obligations for model metadata, labels, row counts, and SQL aliasing.

## Tests to Add or Keep

Do not modify tests in this task.

Useful public tests for a normal development branch would cover:

- deleting a model with two `CASCADE` foreign keys from one related model and
  asserting one related fast-delete query with OR;
- deleting a self-referential many-to-many object and asserting one through-table
  fast-delete query with OR;
- a backend-parameter-limit case where same-model batches remain split when the
  combined parameter count would exceed the limit.

Keep database integration tests even after machine-checking because the formal
model abstracts SQL compiler rendering and backend-specific execution.

## Future FVK Work

Machine-check the constructed K artifacts in a K-enabled environment using the
commands in `fvk/PROOF.md`. If `kprove` does not return `#Top`, update
`fvk/FINDINGS.md` with the residual obligation before making further code
changes.
