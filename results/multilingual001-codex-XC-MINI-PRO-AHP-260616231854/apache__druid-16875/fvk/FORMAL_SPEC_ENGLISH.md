# Formal Spec in English

Status: constructed for FVK audit, not machine-checked.

The K specification abstracts a node role set to two booleans: whether the current service has the MiddleManager role and whether it has the Indexer role. Peon and other unsupported roles are represented by `roles(false, false)`.

K-001 `PEON-CONSTRUCT-NO-LOOKUP`: Constructing `WorkerTaskCountStatsMonitor` with `roles(false, false)` and no task-count provider bindings reaches `unsupportedMode`, performs no provider lookup, and leaves `noError`.

K-002 `PEON-DO-MONITOR-NO-EMIT`: Calling `doMonitor` in `unsupportedMode` emits no worker task-count events and terminates normally.

K-003 `MIDDLE-MANAGER-CONSTRUCT-LOOKUP`: Constructing the monitor with `roles(true, false)` and a worker-provider binding reaches `middleManagerMode`, records exactly one `workerLookup`, and leaves `noError`.

K-004 `MIDDLE-MANAGER-DO-MONITOR-EMITS`: Calling `doMonitor` in `middleManagerMode` emits the MiddleManager worker metric family.

K-005 `INDEXER-CONSTRUCT-LOOKUP`: Constructing the monitor with `roles(false, true)` and an indexer-provider binding reaches `indexerMode`, records exactly one `indexerLookup`, and leaves `noError`.

K-006 `INDEXER-DO-MONITOR-EMITS`: Calling `doMonitor` in `indexerMode` emits the Indexer per-dataSource worker metric family.

K-007 `CONSTRUCTOR-SIGNATURE-FRAME`: The formalized change does not alter the public constructor shape or monitor configuration name; only role-to-provider selection changes.

