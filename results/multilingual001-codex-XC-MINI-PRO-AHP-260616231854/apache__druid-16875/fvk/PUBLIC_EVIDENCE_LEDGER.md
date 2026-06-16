# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic Obligation | Status |
|---|---|---|---|---|
| E-001 | `benchmark/PROBLEM.md` | MiddleManager plus Peons with `WorkerTaskCountStatsMonitor` configured fails in Peons with no implementation for `IndexerTaskCountStatsProvider`. | Peon construction path must not require `IndexerTaskCountStatsProvider`. | Encoded by PO-001 and K claim `PEON-CONSTRUCT-NO-LOOKUP`. |
| E-002 | `benchmark/PROBLEM.md` | "This was alright in earlier versions" for the same MiddleManager monitor configuration. | Preserve compatibility for this configuration. | Encoded by I-001/I-006. |
| E-003 | `benchmark/PROBLEM.md` | "if I run Indexer instead of MM+Peons, the tasks are running successfully." | Indexer path should not be broken while fixing Peon. | Encoded by PO-003 and K claim `INDEXER-CONSTRUCT-LOOKUP`. |
| E-004 | `CliPeon.java` | Peon startup calls `makeInjector(ImmutableSet.of(NodeRole.PEON))`. | Peon role set has no MiddleManager or Indexer role in this startup path. | Encoded as `roles(false, false)` in the mini semantics. |
| E-005 | `CliMiddleManager.java` | MiddleManager returns `NodeRole.MIDDLE_MANAGER` and binds `WorkerTaskCountStatsProvider` to `ForkingTaskRunner`. | MiddleManager constructor path may request only the worker provider. | Encoded by PO-002. |
| E-006 | `CliIndexer.java` | Indexer returns `NodeRole.INDEXER` and binds `IndexerTaskCountStatsProvider` to `WorkerTaskManager`. | Indexer constructor path may request only the indexer provider. | Encoded by PO-003. |
| E-007 | `WorkerTaskCountStatsMonitorTest.java` | Public tests cover MiddleManager and Indexer emission behavior. | Preserve existing emission behavior for those supported roles. | Encoded by PO-002 and PO-003. |
| E-008 | `docs/configuration/index.md` | `WorkerTaskCountStatsMonitor` is described as supported by MiddleManager node types. | Peon is not a required metric-emitting role for this monitor. | Encoded by PO-004. |
| E-009 | `docs/operations/metrics.md` | Metrics docs list both MiddleManager worker metrics and Indexer worker metrics. | Preserve Indexer metrics despite the configuration page ambiguity. | Encoded by PO-003; ambiguity noted in F-003. |

