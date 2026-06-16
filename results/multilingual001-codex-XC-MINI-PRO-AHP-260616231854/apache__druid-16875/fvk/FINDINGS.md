# FVK Findings

Status: constructed, not machine-checked.

## Findings

### F-001: Peon constructor requested an Indexer-only provider

Input/state: `WorkerTaskCountStatsMonitor` configured in a MiddleManager plus Peon deployment; Peon injector has `NodeRole.PEON` and no `IndexerTaskCountStatsProvider` binding.

Observed before V1: the constructor treated every non-MiddleManager role as Indexer and requested `IndexerTaskCountStatsProvider`, causing Guice creation failure before task startup.

Expected: Peon construction should not request either worker task-count provider, because Peon has no provider binding and is not a supported emitting role for this monitor.

Classification: code bug, resolved by V1.

Trace: E-001, E-004, E-008; PO-001, PO-004.

### F-002: Public tests lack the Peon regression case

Input/state: construct `WorkerTaskCountStatsMonitor` with an injector that binds no task-count providers and `ImmutableSet.of(NodeRole.PEON)`.

Observed public coverage: `WorkerTaskCountStatsMonitorTest` declares a Peon injector but does not construct the monitor with `NodeRole.PEON`.

Expected coverage: a regression test should assert construction succeeds and `doMonitor` emits no events for Peon.

Classification: test gap. No test files were modified because the task forbids modifying tests.

Trace: E-001, E-004; PO-001, PO-004.

### F-003: Documentation has a non-blocking support-scope ambiguity

Input/state: public docs for `WorkerTaskCountStatsMonitor`.

Observed: `docs/configuration/index.md` says the monitor is only supported by MiddleManager node types, while `docs/operations/metrics.md` and public tests include Indexer metrics.

Expected: code should preserve both public tested role behaviors while fixing Peon startup. A docs cleanup may be useful separately, but is not necessary for this issue.

Classification: underspecified documentation, non-blocking for code.

Trace: E-003, E-007, E-008, E-009; PO-002, PO-003.

## Proof-derived Findings

No proof obligation forced a new source edit beyond V1. The key proof-derived check was PO-001: the Peon claim would fail under the pre-V1 binary role split because `roles(false, false)` would produce `indexerLookup` and `missingIndexerProvider`. V1 satisfies the obligation by adding the explicit Indexer role guard and an unsupported-role no-op branch.

