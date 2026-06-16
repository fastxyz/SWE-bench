# Iteration Guidance

Status: based on constructed FVK artifacts; no tests or code were executed.

## Source Decision

Keep the V1 source change unchanged.

Reason:

F-001 is resolved by the current `try/except EmptyResultSet` in
`Exists.as_sql()`, and F-002 through F-004 found no additional source-code
problem. PO-001 through PO-006 are all satisfied by the existing V1 patch.

## Recommended Tests to Add or Keep

Do not modify tests in this benchmark task.

For a normal Django development workflow, keep or add tests for:

- `~Exists(Model.objects.none())` combined with another `AND` filter returns
  the same rows as the other filter.
- `Exists(Model.objects.none())` remains empty in a positive filter.
- `~Exists(non_empty_queryset)` still compiles with normal `NOT EXISTS(...)`
  behavior.
- Optional: `~Exists(Model.objects.none())` used in an annotation or select
  position still has valid SQL.

## Machine-Checking Follow-up

The exact commands are in `PROOF.md`. Run them before treating any test as
formally redundant.

## Next Code Iteration

No V2 source edit is recommended. If a future audit expands beyond the issue,
the next target would be broader ORM expression empty-result handling, but no
public evidence in this task justifies changing it here.
