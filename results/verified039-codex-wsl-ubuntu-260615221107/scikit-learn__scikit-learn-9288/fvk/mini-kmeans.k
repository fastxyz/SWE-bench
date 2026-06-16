module MINI-KMEANS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Mode ::= "serial" | "parallel"
  syntax Rng
  syntax Params
  syntax Result
  syntax MaybeResult ::= "none" | some(Result)
  syntax Seeds ::= ".Seeds" | Int ";" Seeds [right]
  syntax Results ::= ".Results" | Result ";" Results [right]

  syntax KItem ::= kmeans(Mode, Rng, Int)
                 | serialLoop(Seeds, MaybeResult)

  syntax Seeds ::= drawSeeds(Rng, Int) [function]
  syntax Result ::= runSingle(Params, Int) [function]
  syntax Int ::= inertia(Result) [function]
  syntax Results ::= mapRun(Params, Seeds) [function]
  syntax Result ::= chooseBest(Results) [function]
                  | bestFrom(MaybeResult, Results) [function]
  syntax KResult ::= Result
endmodule

module MINI-KMEANS
  imports MINI-KMEANS-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <params> P:Params </params>

  rule mapRun(P, .Seeds) => .Results
  rule mapRun(P, S ; SS) => runSingle(P, S) ; mapRun(P, SS)

  rule chooseBest(R ; RS) => bestFrom(some(R), RS)

  rule bestFrom(none, R ; RS) => bestFrom(some(R), RS)
  rule bestFrom(some(B), .Results) => B
  rule bestFrom(some(B), R ; RS) => bestFrom(some(R), RS)
    requires inertia(R) <Int inertia(B)
  rule bestFrom(some(B), R ; RS) => bestFrom(some(B), RS)
    requires notBool (inertia(R) <Int inertia(B))

  rule <k> kmeans(serial, RNG, N) => serialLoop(drawSeeds(RNG, N), none) ... </k>
  rule <k> kmeans(parallel, RNG, N) => chooseBest(mapRun(P, drawSeeds(RNG, N))) ... </k>
       <params> P </params>

  rule <k> serialLoop(.Seeds, B) => bestFrom(B, .Results) ... </k>
  rule <k> serialLoop(S ; SS, B) => serialLoop(SS, bestFrom(B, runSingle(P, S) ; .Results)) ... </k>
       <params> P </params>
endmodule
