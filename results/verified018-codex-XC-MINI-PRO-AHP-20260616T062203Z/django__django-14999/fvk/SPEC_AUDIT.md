# Spec Audit

Status: adequacy audit for the constructed K claims.

| Formal obligation | Public intent match | Verdict |
| --- | --- | --- |
| `RENAME-MODEL-NOOP-SAME-TABLE`: same database table means no DB operations. | Directly matches `benchmark/PROBLEM.md`: "RenameModel with db_table should be a noop." It also covers the reported FK/table side effects by preventing all schema-editor calls on this branch. | pass |
| `RENAME-MODEL-NOOP-DISALLOWED`: disallowed migration means no DB operations. | Existing operation API behavior: `allow_migrate_model()` guards database changes. V1 does not alter this behavior. | pass |
| `RELATED-COUNT`: non-no-op relation loop emits one operation per related object. | Implementation-derived but used only to prove the different-table compatibility branch, supported by public tests that actual renames repoint incoming FKs. | pass |
| `M2M-COUNT`: non-no-op M2M loop emits two operations per applicable M2M relation. | Implementation-derived but used only to prove the different-table compatibility branch, supported by public tests that actual M2M renames remain usable. | pass |
| `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`: different table preserves existing branch. | Matches public tests for actual model table renames; not derived from the issue's buggy same-table behavior. | pass |
| Frame: `state_forwards()` still renames state. | Required by `RenameModel` operation purpose and existing state code. The issue only names database side effects. | pass |
| Frame: no method signature change. | Required by migration operation API compatibility. V1 adds only local branch logic. | pass |

No formal-English obligation is weaker than the public issue intent. The main abstraction is side-effect count rather than concrete SQL text; this is adequate for the issue because the public failure is the presence of any schema-editor work on the same-table branch.
