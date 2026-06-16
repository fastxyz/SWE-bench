# Intent Specification

Status: constructed for FVK audit, not machine-checked.

## Scope

This FVK pass audits the V1 production change for `WorkerTaskCountStatsMonitor`, plus the public role/provider binding sites needed to explain the reported Peon injector failure. It does not attempt to formalize the entire Druid repository.

## Required Behaviors

I-001: In a MiddleManager plus Peon deployment, including `org.apache.druid.server.metrics.WorkerTaskCountStatsMonitor` in `druid.monitoring.monitors` must not prevent Peon ingestion tasks from starting.

I-002: A Peon has `NodeRole.PEON` and does not have an `IndexerTaskCountStatsProvider` binding. Therefore constructing this monitor in a Peon injector must not request `IndexerTaskCountStatsProvider`.

I-003: MiddleManager behavior must be preserved: with `NodeRole.MIDDLE_MANAGER`, the monitor uses `WorkerTaskCountStatsProvider` and emits the MiddleManager worker task and task-slot metrics.

I-004: Indexer behavior must be preserved: with `NodeRole.INDEXER`, the monitor uses `IndexerTaskCountStatsProvider` and emits Indexer per-dataSource worker task metrics.

I-005: Unsupported roles, including Peon, have no public provider binding for this monitor and should be harmless no-ops rather than failing injector creation.

I-006: The public constructor signature and monitor class name must remain compatible with existing monitor configuration and tests.

