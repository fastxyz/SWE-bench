# FVK Notes

## Decisions

D-001. Kept V1 unchanged. This follows from F-001 and F-004: the original bug is
the raw RHS query appearing in `GROUP BY`, and PO-002 plus PO-007 prove that the
reported non-correlated RHS now contributes an empty RHS group-by list.

D-002. Kept the fix at `Query.get_group_by_cols()` rather than moving it to
`RelatedIn.as_sql()`. F-002 identifies correlated subquery dependency reporting
as part of the compatibility frame, and PO-003 through PO-005 show that V1
preserves scalar external columns, the possibly-multivalued fallback, and alias
references.

D-003. Made no test edits. F-003 and PO-008 state that the proof is constructed,
not machine-checked, and the task forbids modifying test files.

D-004. Added two `.k` artifacts in `fvk/` in addition to the five requested
Markdown artifacts. This is required by the FVK method documentation's formal
core contract and is referenced by PO-008.

## Source Changes

No source files were changed during the FVK pass. The only production-code
change remains the V1 edit in `repo/django/db/models/sql/query.py`.

## Assumptions

The FVK model abstracts SQL compilation to the group-by dependency list because
that is the defect axis identified in F-001. This abstraction is adequate under
PO-001 and PO-007 because the reported PostgreSQL error is caused by the raw RHS
query being compiled from that dependency list, not by the later `HAVING IN`
predicate rendering path.
