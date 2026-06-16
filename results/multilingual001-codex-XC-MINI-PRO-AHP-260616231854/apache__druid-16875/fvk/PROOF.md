# Constructed Proof

Status: constructed, not machine-checked.

## Summary

The V1 code satisfies the role/provider safety contract for `WorkerTaskCountStatsMonitor`: MiddleManager uses the worker provider, Indexer uses the indexer provider, and Peon or other unsupported roles use neither provider and no-op in `doMonitor`.

## Machine-check Commands Not Run

The task forbids running K tooling. These are the commands to run later:

```sh
kompile fvk/mini-java-monitor.k --backend haskell
kast --backend haskell fvk/worker-task-count-stats-monitor-spec.k
kprove fvk/worker-task-count-stats-monitor-spec.k
```

Expected machine-check outcome, if the mini semantics parses as written: all claims reduce to `#Top`.

## Proof Sketch

### PO-001: Peon constructor provider safety

Initial symbolic state:

- `<k> construct(roles(false, false)) </k>`
- `<bindings> bindings(false, false) </bindings>`
- `<mode> uninitialized </mode>`
- `<lookups> .LookupTrace </lookups>`
- `<error> noError </error>`

The only matching constructor rule for `roles(false, false)` is the unsupported-role rule. By one rewrite step it reaches:

- `<k> .K </k>`
- `<mode> unsupportedMode </mode>`
- `<lookups> .LookupTrace </lookups>`
- `<error> noError </error>`

No rule performs `indexerLookup`, so the reported missing `IndexerTaskCountStatsProvider` failure is unreachable on this path.

### PO-004: Peon no-op emission

Initial symbolic state:

- `<k> doMonitor </k>`
- `<mode> unsupportedMode </mode>`
- `<events> .Events </events>`

The unsupported `doMonitor` rule rewrites to `<k> .K </k>` and keeps `<events> .Events </events>`. This establishes no emitted worker task-count metrics and normal return.

### PO-002: MiddleManager preservation

For `roles(true, false)` with `bindings(true, false)`, the MiddleManager constructor rule fires first, matching the Java `if (isMiddleManager)` priority. The result is `middleManagerMode`, a single `workerLookup`, and `noError`.

From `middleManagerMode`, the `doMonitor` rule emits `middleManagerEvents`. This abstracts the five existing MiddleManager metric emissions in the Java source and matches the public tests.

### PO-003: Indexer preservation

For `roles(false, true)` with `bindings(false, true)`, the Indexer constructor rule fires, matching the Java `else if (isIndexer)` branch. The result is `indexerMode`, a single `indexerLookup`, and `noError`.

From `indexerMode`, the `doMonitor` rule emits `indexerEvents`. This abstracts the existing Indexer per-dataSource metric emissions and matches the public tests.

### PO-005: Compatibility frame

The Java diff changes only private fields and constructor/body branch conditions. The class name, constructor parameters, provider interfaces, `doMonitor(ServiceEmitter)` signature, metric names, and helper signatures are unchanged. Public monitor configuration remains compatible.

## Adequacy and Completeness Check

The proof covers every role class relevant to the issue and public behavior:

- MiddleManager, which binds `WorkerTaskCountStatsProvider`.
- Indexer, which binds `IndexerTaskCountStatsProvider`.
- Peon/unsupported, which binds neither provider.

There are no loops or recursion, so no circularity claim is required. Termination is immediate in the model because each command rewrites in one step.

The proof is sound only with respect to the mini semantics and is not machine-checked. It is adequate for the audited defect because the modeled observable is exactly the defect axis: whether constructor execution requests an unbound provider.

## Test-redundancy Recommendation

No tests should be removed. The public MiddleManager and Indexer tests exercise integration details outside the abstract K proof, and there is no public Peon regression test to classify as redundant. A new Peon regression test is recommended if test edits are allowed in a future task.

