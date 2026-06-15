# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not surface a production source defect in the V1 fix.

## Why no code change is needed

- F1 confirms that the method signature now matches the public issue.
- PO2 confirms that the removed `using` argument is inferred as `self.connection.alias`.
- PO3 confirms that the transaction/cursor/SQL-list execution behavior was preserved.
- PO4 and PO5 confirm that in-repository production source call sites and backend overrides are compatible with the new API.

## Follow-up outside this benchmark

- Update visible tests that still call `execute_sql_flush(connection.alias, sql_list)` to the new one-argument call shape. This is identified by F2 but prohibited by the benchmark instructions.
- If this were a release-facing public API change, consider release-note or deprecation-policy handling for third-party backend overrides. F3 records that this is outside the allowed evidence here and does not block the issue-requested change.
- Run the recorded K commands only in an environment where K tooling is available. This benchmark explicitly forbids doing so here.

## Future tests to add or revise

- A source-level or behavioral test should call `connection.ops.execute_sql_flush(sql_list)` directly.
- A management-command integration test should confirm the `flush` command works without passing `database` into `execute_sql_flush()`.
- Legacy two-argument direct-call tests should not be used as evidence that V1 is wrong because they conflict with the public issue intent.
