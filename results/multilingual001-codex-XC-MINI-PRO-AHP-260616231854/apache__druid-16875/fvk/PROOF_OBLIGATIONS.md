# Proof Obligations

Status: constructed, not machine-checked.

## Commands Not Executed

Per task instructions, these commands are recorded but not run:

```sh
kompile fvk/mini-java-monitor.k --backend haskell
kast --backend haskell fvk/worker-task-count-stats-monitor-spec.k
kprove fvk/worker-task-count-stats-monitor-spec.k
```

## Obligations

### PO-001: Peon constructor provider safety

Claim: `PEON-CONSTRUCT-NO-LOOKUP`.

For `roles(false, false)` and `bindings(false, false)`, construction must end with:

- mode `unsupportedMode`;
- lookup trace `.LookupTrace`;
- error `noError`.

This discharges F-001 for the reported Peon startup path.

### PO-002: MiddleManager constructor and emission preservation

Claims: `MIDDLE-MANAGER-CONSTRUCT-LOOKUP`, `MIDDLE-MANAGER-DO-MONITOR-EMITS`.

For `roles(true, false)` and a worker provider binding, construction must use only `workerLookup`, and `doMonitor` must emit the MiddleManager worker metric family. This preserves public tests and provider binding behavior.

### PO-003: Indexer constructor and emission preservation

Claims: `INDEXER-CONSTRUCT-LOOKUP`, `INDEXER-DO-MONITOR-EMITS`.

For `roles(false, true)` and an indexer provider binding, construction must use only `indexerLookup`, and `doMonitor` must emit the Indexer per-dataSource worker metric family. This preserves the public Indexer behavior noted in the issue and tests.

### PO-004: Unsupported-role no-op

Claims: `PEON-CONSTRUCT-NO-LOOKUP`, `PEON-DO-MONITOR-NO-EMIT`.

For unsupported roles, including Peon, the monitor must be constructible without task-count provider bindings and must emit no worker task-count events. This is the minimal behavior needed to prevent inherited monitor configuration from breaking Peons.

### PO-005: Compatibility frame

Claim: compatibility audit in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

The fix must not change the monitor class name, constructor parameters, `doMonitor` signature, metric names, or provider interfaces. Existing monitor configuration strings and public tests must remain compatible.

## Test Recommendations

Do not delete tests. If test changes were allowed, add a Peon regression test that constructs the monitor with `NodeRole.PEON`, an injector with no task-count providers, calls `doMonitor`, and asserts zero emitted events.

