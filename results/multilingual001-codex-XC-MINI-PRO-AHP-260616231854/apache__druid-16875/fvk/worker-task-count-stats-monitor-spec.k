// Constructed FVK artifact, not machine-checked.
// Exact commands are listed in PROOF.md and PROOF_OBLIGATIONS.md.

requires "mini-java-monitor.k"

module WORKER-TASK-COUNT-STATS-MONITOR-SPEC
  imports MINI-JAVA-MONITOR

  // SPEC-PROVENANCE:
  // - E-001/E-004: Peons start with NodeRole.PEON and lack IndexerTaskCountStatsProvider.
  // - obligation: Peon construction performs no provider lookup and has no construction error.
  claim [PEON-CONSTRUCT-NO-LOOKUP]:
    <k> construct(roles(false, false)) => .K </k>
    <mode> uninitialized => unsupportedMode </mode>
    <lookups> .LookupTrace => .LookupTrace </lookups>
    <bindings> bindings(false, false) </bindings>
    <error> noError => noError </error>
    <events> .Events </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-008: Peon is not a supported emitting role for this monitor.
  // - obligation: unsupported mode is harmless and emits no task-count metrics.
  claim [PEON-DO-MONITOR-NO-EMIT]:
    <k> doMonitor => .K </k>
    <mode> unsupportedMode </mode>
    <lookups> .LookupTrace </lookups>
    <bindings> bindings(false, false) </bindings>
    <error> noError </error>
    <events> .Events => .Events </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005/E-007: MiddleManager binds WorkerTaskCountStatsProvider and public tests assert its metrics.
  // - obligation: MiddleManager construction uses only the worker provider.
  claim [MIDDLE-MANAGER-CONSTRUCT-LOOKUP]:
    <k> construct(roles(true, false)) => .K </k>
    <mode> uninitialized => middleManagerMode </mode>
    <lookups> .LookupTrace => workerLookup .LookupTrace </lookups>
    <bindings> bindings(true, false) </bindings>
    <error> noError => noError </error>
    <events> .Events </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007: Public tests assert MiddleManager worker metric events.
  // - obligation: MiddleManager doMonitor emits the MiddleManager metric family.
  claim [MIDDLE-MANAGER-DO-MONITOR-EMITS]:
    <k> doMonitor => .K </k>
    <mode> middleManagerMode </mode>
    <lookups> workerLookup .LookupTrace </lookups>
    <bindings> bindings(true, false) </bindings>
    <error> noError </error>
    <events> .Events => middleManagerEvents </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003/E-006/E-009: Indexer succeeds and binds IndexerTaskCountStatsProvider.
  // - obligation: Indexer construction uses only the indexer provider.
  claim [INDEXER-CONSTRUCT-LOOKUP]:
    <k> construct(roles(false, true)) => .K </k>
    <mode> uninitialized => indexerMode </mode>
    <lookups> .LookupTrace => indexerLookup .LookupTrace </lookups>
    <bindings> bindings(false, true) </bindings>
    <error> noError => noError </error>
    <events> .Events </events>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-007/E-009: Public tests and metrics docs assert Indexer worker metrics.
  // - obligation: Indexer doMonitor emits the Indexer metric family.
  claim [INDEXER-DO-MONITOR-EMITS]:
    <k> doMonitor => .K </k>
    <mode> indexerMode </mode>
    <lookups> indexerLookup .LookupTrace </lookups>
    <bindings> bindings(false, true) </bindings>
    <error> noError </error>
    <events> .Events => indexerEvents </events>
    [all-path]
endmodule

