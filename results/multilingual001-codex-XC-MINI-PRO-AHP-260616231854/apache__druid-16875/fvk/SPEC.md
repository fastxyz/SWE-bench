# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audit target is the V1 fix to `repo/server/src/main/java/org/apache/druid/server/metrics/WorkerTaskCountStatsMonitor.java`. Supporting source evidence is limited to the role and provider binding sites in `CliPeon`, `CliMiddleManager`, and `CliIndexer`, plus public docs/tests that describe the monitor behavior.

The unit under proof has no loops. The relevant behavior is constructor provider selection followed by `doMonitor` emission selection.

## Intent Summary

The issue reports that `WorkerTaskCountStatsMonitor` in a MiddleManager plus Peon deployment causes Peon injector creation to fail because `IndexerTaskCountStatsProvider` is not bound. The intended behavior is that this monitor remains usable in the MiddleManager configuration, Peons do not fail startup, and existing MiddleManager/Indexer metrics continue to work.

## Public Intent Ledger

This is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

| ID | Evidence | Obligation |
|---|---|---|
| E-001 | Peon failure is "No implementation for ... IndexerTaskCountStatsProvider" at `WorkerTaskCountStatsMonitor.<init>`. | Peon constructor path must not request the Indexer provider. |
| E-002 | Same MiddleManager monitor config worked before. | Preserve MM plus Peon configuration compatibility. |
| E-003 | Indexer mode succeeds. | Preserve Indexer monitor behavior. |
| E-004 | `CliPeon.run` calls `makeInjector(ImmutableSet.of(NodeRole.PEON))`. | Peon role is neither MiddleManager nor Indexer. |
| E-005 | `CliMiddleManager` binds `WorkerTaskCountStatsProvider`. | MiddleManager may resolve the worker provider. |
| E-006 | `CliIndexer` binds `IndexerTaskCountStatsProvider`. | Indexer may resolve the indexer provider. |
| E-007 | Public tests assert MiddleManager and Indexer emissions. | Do not regress those paths. |
| E-008 | Configuration docs say worker monitor is only supported by MiddleManager node types. | Peon is not required to emit metrics. |
| E-009 | Metrics docs list Indexer worker metrics. | Indexer support remains in scope. |

## Formal Model

The supporting K core is:

- `fvk/mini-java-monitor.k`
- `fvk/worker-task-count-stats-monitor-spec.k`

The mini semantics abstracts the Java role set to `roles(hasMiddleManager, hasIndexer)`. This is property-complete for the defect because the issue hinges on whether the constructor does or does not request the Indexer provider. Peon and other unsupported roles are represented as `roles(false, false)`.

The modeled state cells are:

- `<mode>`: `uninitialized`, `middleManagerMode`, `indexerMode`, or `unsupportedMode`.
- `<lookups>`: provider lookup trace, either no lookup, `workerLookup`, or `indexerLookup`.
- `<bindings>`: whether worker and indexer provider bindings exist.
- `<error>`: `noError`, `missingWorkerProvider`, or `missingIndexerProvider`.
- `<events>`: abstract MiddleManager events, Indexer events, or no events.

## Claims

S-001 Peon construction safety: `construct(roles(false, false))` with no task-count provider bindings reaches `unsupportedMode`, performs no provider lookup, and leaves `noError`.

S-002 Peon monitor no-op: `doMonitor` in `unsupportedMode` emits no worker task-count events and returns normally.

S-003 MiddleManager construction preservation: `construct(roles(true, false))` with a worker provider binding reaches `middleManagerMode`, performs exactly `workerLookup`, and leaves `noError`.

S-004 MiddleManager emission preservation: `doMonitor` in `middleManagerMode` emits the MiddleManager worker task-count metric family.

S-005 Indexer construction preservation: `construct(roles(false, true))` with an indexer provider binding reaches `indexerMode`, performs exactly `indexerLookup`, and leaves `noError`.

S-006 Indexer emission preservation: `doMonitor` in `indexerMode` emits the Indexer per-dataSource worker task-count metric family.

S-007 Compatibility frame: constructor signature, monitor class name, and `doMonitor` signature remain unchanged.

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim, and `fvk/SPEC_AUDIT.md` compares those paraphrases to the intent. All required behaviors pass. The only ambiguity is documentation-level: a configuration table says MiddleManager-only, while metrics docs and public tests include Indexer metrics. The spec preserves Indexer behavior because it is public tested behavior and the issue explicitly says Indexer succeeds.

