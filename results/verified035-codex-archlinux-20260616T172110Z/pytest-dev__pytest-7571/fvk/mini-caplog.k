requires "domains.md"

module MINI-CAPLOG-SYNTAX
  imports INT-SYNTAX

  syntax MaybeInt ::= "none" | "some" "(" Int ")"
  syntax State ::= "state" "(" Int "," Int "," MaybeInt "," MaybeInt ")"
  syntax Exp ::= "initialState" "(" Int "," Int ")"
               | "setLevel" "(" Exp "," Int ")" [strict(1)]
               | "finalize" "(" Exp ")" [strict]
               | "atLevel" "(" Exp "," Int ")" [strict(1)]
               | State
endmodule

module MINI-CAPLOG
  imports MINI-CAPLOG-SYNTAX
  imports INT

  configuration <k> $PGM:Exp </k>

  // State order:
  // state(handlerLevel, loggerLevel, savedHandlerLevel, savedLoggerLevel)
  rule <k> initialState(H, G) => state(H, G, none, none) </k>

  // First caplog.set_level: save original handler/logger levels, then mutate both.
  rule <k> setLevel(state(H, G, none, none), L)
        => state(L, L, some(H), some(G)) </k>

  // Repeated caplog.set_level: preserve first saved values, mutate current levels.
  rule <k> setLevel(state(H, G, some(SH), some(SG)), L)
        => state(L, L, some(SH), some(SG)) </k>

  // No set_level: finalization is a frame over modeled level state.
  rule <k> finalize(state(H, G, none, none))
        => state(H, G, none, none) </k>

  // With saved values: restore the original handler and logger levels.
  rule <k> finalize(state(H, G, some(SH), some(SG)))
        => state(SH, SG, some(SH), some(SG)) </k>

  // caplog.at_level is block-scoped and restores its pre-block levels.
  rule <k> atLevel(state(H, G, SH, SG), L)
        => state(H, G, SH, SG) </k>
endmodule
