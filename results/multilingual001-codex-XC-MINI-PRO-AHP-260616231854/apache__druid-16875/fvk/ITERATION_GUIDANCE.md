# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

FVK finding F-001 is resolved by the current code because `WorkerTaskCountStatsMonitor` now checks `NodeRole.INDEXER` before resolving `IndexerTaskCountStatsProvider`, and Peon/unsupported roles do not resolve either provider. The proof obligations PO-001 and PO-004 specifically target the reported failure path.

No additional source edit is justified by the FVK artifacts:

- PO-002 confirms the MiddleManager provider and emission path is preserved.
- PO-003 confirms the Indexer provider and emission path is preserved.
- PO-005 confirms public signatures and monitor configuration compatibility are preserved.
- F-002 is a test gap, but test files are forbidden in this task.
- F-003 is a documentation ambiguity, not a source-code defect required to fix Peon startup.

## Future Work

If test edits are allowed later, add a regression test for `NodeRole.PEON` with an injector that binds no task-count provider. The expected behavior is successful construction, `doMonitor` returning `true`, and zero emitted events.

If documentation cleanup is in scope later, reconcile the configuration table's "Only supported by MiddleManager node types" language with the metrics docs and tests that include Indexer metrics.

