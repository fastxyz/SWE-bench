// Constructed FVK artifact, not machine-checked.
// A small K-style semantics for the WorkerTaskCountStatsMonitor role/provider fragment.

module MINI-JAVA-MONITOR-SYNTAX
  imports BOOL-SYNTAX

  syntax Roles ::= "roles" "(" Bool "," Bool ")"  // hasMiddleManager, hasIndexer
  syntax Program ::= "construct" "(" Roles ")" | "doMonitor"

  syntax Mode ::= "uninitialized" | "middleManagerMode" | "indexerMode" | "unsupportedMode"
  syntax Lookup ::= "workerLookup" | "indexerLookup"
  syntax LookupTrace ::= ".LookupTrace" | Lookup LookupTrace [right]
  syntax Bindings ::= "bindings" "(" Bool "," Bool ")" // hasWorkerProvider, hasIndexerProvider
  syntax Error ::= "noError" | "missingWorkerProvider" | "missingIndexerProvider"
  syntax EventTrace ::= ".Events" | "middleManagerEvents" | "indexerEvents"
endmodule

module MINI-JAVA-MONITOR
  imports MINI-JAVA-MONITOR-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Program </k>
    <mode> uninitialized </mode>
    <lookups> .LookupTrace </lookups>
    <bindings> bindings(false, false) </bindings>
    <error> noError </error>
    <events> .Events </events>

  // Constructor role selection. MiddleManager takes precedence, matching the Java if/else-if.
  rule
    <k> construct(roles(true, IX:Bool)) => .K </k>
    <mode> _ => middleManagerMode </mode>
    <lookups> _ => workerLookup .LookupTrace </lookups>
    <bindings> bindings(true, IX) </bindings>
    <error> _ => noError </error>

  rule
    <k> construct(roles(true, IX:Bool)) => .K </k>
    <mode> _ => middleManagerMode </mode>
    <lookups> _ => workerLookup .LookupTrace </lookups>
    <bindings> bindings(false, IX) </bindings>
    <error> _ => missingWorkerProvider </error>

  rule
    <k> construct(roles(false, true)) => .K </k>
    <mode> _ => indexerMode </mode>
    <lookups> _ => indexerLookup .LookupTrace </lookups>
    <bindings> bindings(WK:Bool, true) </bindings>
    <error> _ => noError </error>

  rule
    <k> construct(roles(false, true)) => .K </k>
    <mode> _ => indexerMode </mode>
    <lookups> _ => indexerLookup .LookupTrace </lookups>
    <bindings> bindings(WK:Bool, false) </bindings>
    <error> _ => missingIndexerProvider </error>

  // Peon and other unsupported roles: no provider lookup and no construction error.
  rule
    <k> construct(roles(false, false)) => .K </k>
    <mode> _ => unsupportedMode </mode>
    <lookups> _ => .LookupTrace </lookups>
    <error> _ => noError </error>

  rule
    <k> doMonitor => .K </k>
    <mode> middleManagerMode </mode>
    <events> _ => middleManagerEvents </events>

  rule
    <k> doMonitor => .K </k>
    <mode> indexerMode </mode>
    <events> _ => indexerEvents </events>

  rule
    <k> doMonitor => .K </k>
    <mode> unsupportedMode </mode>
    <events> _ => .Events </events>
endmodule

