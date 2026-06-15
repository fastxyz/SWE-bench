module MINI-CACHE-CULL-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Cutoff ::= "none" | "some" "(" Int ")"
  syntax Result ::= "rows" "(" Int ")" | "typeError"
  syntax Cmd ::= "cull" "(" Int "," Int "," Int "," Cutoff ")"
  syntax KResult ::= Result
endmodule

module MINI-CACHE-CULL
  imports MINI-CACHE-CULL-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  syntax Int ::= cullNum(Int, Int) [function]
  rule cullNum(NUM, FREQ) => NUM /Int FREQ requires FREQ =/=Int 0

  rule <k> cull(0, MAX, NUM, CUTOFF) => rows(0) ... </k>
    requires NUM >=Int 0

  rule <k> cull(FREQ, MAX, NUM, CUTOFF) => rows(NUM) ... </k>
    requires FREQ >Int 0 andBool NUM >=Int 0 andBool NUM <=Int MAX

  rule <k> cull(FREQ, MAX, NUM, CUTOFF) => rows(0) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM >Int MAX
     andBool cullNum(NUM, FREQ) ==Int NUM

  rule <k> cull(FREQ, MAX, NUM, some(CUTOFF)) => rows(NUM -Int cullNum(NUM, FREQ)) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM >Int MAX
     andBool cullNum(NUM, FREQ) =/=Int NUM

  rule <k> cull(FREQ, MAX, NUM, none) => rows(NUM) ... </k>
    requires FREQ >Int 0
     andBool NUM >=Int 0
     andBool NUM >Int MAX
     andBool cullNum(NUM, FREQ) =/=Int NUM
endmodule
