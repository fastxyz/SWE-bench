# ITERATION GUIDANCE

Status: V1 stands; no V2 source edit is justified by the FVK findings.

## Decision

Keep V1 unchanged.

Rationale:

- F-001 is resolved by PO-1: the same-table branch returns before all database-mutating calls.
- F-003 is resolved by PO-3: the different-table branch remains structurally unchanged.
- PO-4 confirms `state_forwards()` remains untouched.
- PO-5 confirms the public operation API remains compatible.

## Suggested Future Tests

Do not edit tests in this task. For a normal Django development pass, add or keep tests that check:

- `RenameModel` from `Author` to `NewAuthor` with unchanged explicit `db_table` emits no collected SQL.
- The same scenario with an incoming `ForeignKey` emits no FK drop/create SQL.
- The same scenario on SQLite does not remake related tables.
- `state_forwards()` still renames the model state and repoints migration-state references.
- Existing different-table rename tests continue to cover table, FK, and M2M behavior.

## Test Redundancy

No test removal is recommended. The proof was constructed but not machine-checked, and the task forbids running the proof commands.

## If Requirements Change

If public intent later states that same-table model renames must still rename auto-created M2M source columns, then F-002 becomes a real code/spec conflict and PO-1 must be weakened. Under the current issue text, that change is rejected because it violates the explicit database no-op requirement.
