# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

Changed public symbol: `org.apache.druid.server.metrics.WorkerTaskCountStatsMonitor`.

Compatibility checks:

| Surface | Status | Evidence |
|---|---|---|
| Class name used in `druid.monitoring.monitors` | unchanged | V1 edits only constructor body and `doMonitor` branch guard. |
| Constructor parameters | unchanged | Still `WorkerTaskCountStatsMonitor(Injector, @Self Set<NodeRole>)`. |
| `doMonitor(ServiceEmitter)` signature and return type | unchanged | Still overrides `AbstractMonitor.doMonitor` and returns `true`. |
| MiddleManager provider contract | unchanged | Still resolves `WorkerTaskCountStatsProvider` for `NodeRole.MIDDLE_MANAGER`. |
| Indexer provider contract | unchanged | Still resolves `IndexerTaskCountStatsProvider` for `NodeRole.INDEXER`. |
| Peon startup compatibility | improved | Peon no longer has to bind `IndexerTaskCountStatsProvider` merely because the monitor class is configured. |
| Public tests | no edits | Test files were read as evidence only and were not modified. |

No public callsite or override requires a code change beyond V1.

