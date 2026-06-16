# FVK Notes

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit found that the original V1 patch directly
discharges the issue-backed obligation: aggregate expressions referencing a
selected annotation with `contains_over_clause` now force the existing aggregate
subquery wrapper.

## Trace to Findings and Obligations

Finding F1 is the operative bug. It is discharged by:

- PO1: `refs_window` is computed from `aggregate.get_refs()` and the referenced
  annotation's `contains_over_clause`.
- PO2: `refs_window` participates in the wrapper condition.
- PO3: the wrapper path preserves selected annotation `Ref`s as outer aliases,
  avoiding inline window SQL.

No additional code edit was made because the source already implements these
obligations at `repo/django/db/models/sql/query.py:419-460`, and the existing
wrapper machinery at `repo/django/db/models/sql/query.py:493-520` provides the
needed alias-preserving SQL shape.

PO4 justifies keeping the patch narrow: existing wrapper triggers remain in the
same disjunction, and the no-trigger direct path remains available. PO5 confirms
there is no public API or callsite compatibility change.

Finding F2 records a broader possible feature, direct `Aggregate(Window(...))`
expression lifting. I did not change the code for that case because PO6 marks it
outside the public intent established by the issue example and in-repo docs. It
would need a different expression-lifting rewrite, not merely a broader boolean
wrapper condition.

Finding F3 records the execution boundary. No tests, Python code, or K tooling
were run, per task instructions. The emitted K commands are listed for later
machine checking in `fvk/PROOF.md`.
