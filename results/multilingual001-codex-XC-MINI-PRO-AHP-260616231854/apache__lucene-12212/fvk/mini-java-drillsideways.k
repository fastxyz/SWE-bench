requires "domains.md"

module MINI-JAVA-DRILLSIDEWAYS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Phase ::= "base" | "dim" "(" Int ")"
  syntax Step ::= "nextApprox" "(" Phase "," Int ")"
                | "advanceApprox" "(" Phase "," Int ")"
                | "confirm" "(" Phase "," Int ")"
                | "collectBase" "(" Int ")"
                | "collectDim" "(" Int "," Int ")"
                | "skip" "(" Int ")"
  syntax Steps ::= List{Step, ","}
  syntax KResult ::= Int | Bool | Step | Steps
endmodule

module MINI-JAVA-DRILLSIDEWAYS
  imports MINI-JAVA-DRILLSIDEWAYS-SYNTAX
  imports INT
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:K </k>
    <pos> .Map </pos>
    <confirmed> .Map </confirmed>
    <accepted> .Map </accepted>
    <trace> .List </trace>

  syntax Bool ::= hasTwoPhase(Phase) [function]
  syntax Bool ::= exact(Phase, Int) [function]
  syntax Bool ::= live(Int) [function]
  syntax Bool ::= confirmed(Map, Phase, Int) [function]
  syntax Bool ::= accepted(Map, Phase, Int) [function]

  rule confirmed(C:Map, P:Phase, D:Int) => (C [ P |-> D ] ==K true)
    [function]

  rule accepted(A:Map, P:Phase, D:Int) => (A [ P |-> D ] ==K true)
    [function]

  rule
    <k> nextApprox(P:Phase, D:Int) => .K ... </k>
    <pos> POS => POS [ P <- D ] </pos>
    <trace> T => T ListItem(nextApprox(P, D)) </trace>

  rule
    <k> advanceApprox(P:Phase, D:Int) => .K ... </k>
    <pos> POS => POS [ P <- D ] </pos>
    <trace> T => T ListItem(advanceApprox(P, D)) </trace>

  rule
    <k> confirm(P:Phase, D:Int) => exact(P, D) ... </k>
    <pos> ... P |-> D ... </pos>
    <confirmed> C => C [ P |-> D ] </confirmed>
    <trace> T => T ListItem(confirm(P, D)) </trace>
    requires notBool confirmed(C, P, D)

  rule
    <k> collectBase(D:Int) => .K ... </k>
    <accepted> A => A [ base <- D ] </accepted>
    <trace> T => T ListItem(collectBase(D)) </trace>

  rule
    <k> collectDim(I:Int, D:Int) => .K ... </k>
    <accepted> A => A [ dim(I) <- D ] </accepted>
    <trace> T => T ListItem(collectDim(I, D)) </trace>

  rule
    <k> skip(D:Int) => .K ... </k>
    <trace> T => T ListItem(skip(D)) </trace>
endmodule
