# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the original bug as F-001 and found
that V1 satisfies the relevant proof obligations without introducing a new
source-code finding.

## Trace to Findings and Proof Obligations

The decision to keep the `try/except EmptyResultSet` inside
`Exists.as_sql()` is justified by F-001 and PO-001. F-001 identifies the
pre-V1 failure: `~Exists(empty_queryset)` leaked `EmptyResultSet` before its
internal negation could be applied. PO-001 requires the negated empty case to
return a true SQL predicate, which V1 does with `'%s = %s', (1, 1)`.

The decision to leave positive `Exists(empty_queryset)` behavior unchanged is
justified by F-002 and PO-002. V1 re-raises `EmptyResultSet` when
`self.negated` is false, preserving the always-false meaning of a positive
empty `Exists`.

The decision to leave non-empty `Exists` behavior unchanged is justified by
F-004, PO-003, and PO-004. When `super().as_sql()` succeeds, V1 follows the
existing paths: return the normal `EXISTS(...)` SQL for positive `Exists`, or
wrap it with `NOT` for negated `Exists`.

The decision to keep a concrete SQL predicate instead of returning `('', [])`
is justified by F-003, PO-001, and PO-006. A concrete predicate works as a
WHERE child and also remains valid when `Exists` is compiled in SELECT or
annotation contexts where an omitted SQL string would not be a valid
expression.

The decision not to edit `WhereNode.as_sql()` is justified by F-001, PO-001,
and PO-005. Negation is encapsulated by `Exists.__invert__()`, so the fix must
convert the negated empty-subquery case before the exception reaches generic
WHERE handling. PO-005 confirms that once V1 returns SQL, the other `AND`
predicate is preserved by the existing `WhereNode` path.

The decision not to modify tests is justified by F-005 and PO-007, and also by
the task constraint forbidding test edits. The FVK proof artifacts are
constructed but not machine-checked, so any test-redundancy conclusion remains
conditional on running the emitted `kompile` and `kprove` commands in a proper
environment.

## Source Changes After FVK

No source changes were made after the V1 patch. The only new files in this
phase are the FVK artifacts under `fvk/` and this report.
