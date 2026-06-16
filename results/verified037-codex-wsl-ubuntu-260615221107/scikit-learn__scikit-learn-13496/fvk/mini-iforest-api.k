module MINI-IFOREST-API-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX

  // Small value universe for the public constructor API. The proof is about
  // argument placement and warm_start propagation, not numeric validation.
  syntax Value ::= Bool | Int
                 | "Auto" | "Legacy" | "Old" | "New" | "NoneValue"
                 | "StateValue" | "OneFloat"

  syntax Key ::= "kNEstimators" | "kMaxSamples" | "kContamination"
               | "kMaxFeatures" | "kBootstrap" | "kNJobs"
               | "kBehaviour" | "kRandomState" | "kVerbose"
               | "kWarmStart"

  syntax Call ::= "oldCtor" "(" Value "," Value "," Value "," Value ","
                              Value "," Value "," Value "," Value ","
                              Value ")"
                | "newCtor" "(" Value "," Value "," Value "," Value ","
                              Value "," Value "," Value "," Value ","
                              Value "," Bool ")"

  syntax KResult ::= Map
endmodule

module MINI-IFOREST-API
  imports MINI-IFOREST-API-SYNTAX
  imports MAP
  imports BOOL

  configuration
    <k> $PGM:Call </k>
    <state> .Map </state>

  syntax Map ::= iforestState(Value, Value, Value, Value, Value,
                              Value, Value, Value, Value, Bool) [function]

  rule iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, W) =>
       kNEstimators  |-> NE
       kMaxSamples   |-> MS
       kContamination |-> C
       kMaxFeatures  |-> MF
       kBootstrap    |-> B
       kNJobs        |-> NJ
       kBehaviour    |-> BH
       kRandomState  |-> RS
       kVerbose      |-> V
       kWarmStart    |-> W

  // Constructor without the newly exposed argument. This models the previous
  // public positional call shape and the new default warm_start=False.
  rule
    <k> oldCtor(NE, MS, C, MF, B, NJ, BH, RS, V) => .K </k>
    <state> _ => iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, false) </state>

  // Constructor with the newly exposed public argument appended after verbose.
  rule
    <k> newCtor(NE, MS, C, MF, B, NJ, BH, RS, V, W) => .K </k>
    <state> _ => iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, W) </state>
endmodule
