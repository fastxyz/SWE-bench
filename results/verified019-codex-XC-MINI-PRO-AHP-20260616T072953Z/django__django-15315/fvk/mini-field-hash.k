module MINI-FIELD-HASH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax ModelKey ::= noModel | model(Int)
  syntax FieldState ::= field(Int, ModelKey)
  syntax Exp ::= Int | Bool | ModelKey | FieldState
               | hash(Exp)              [strict]
               | attach(Exp, Exp)       [strict]
               | eq(Exp, Exp)           [strict]
  syntax KResult ::= Int | Bool | ModelKey | FieldState
endmodule

module MINI-FIELD-HASH
  imports MINI-FIELD-HASH-SYNTAX
  imports INT
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  rule <k> hash(field(C:Int, _:ModelKey)) => C ... </k>
  rule <k> attach(field(C:Int, _:ModelKey), M:ModelKey) => field(C, M) ... </k>
  rule <k> eq(field(C1:Int, M1:ModelKey), field(C2:Int, M2:ModelKey))
        => (C1 ==Int C2 andBool M1 ==K M2)
       ... </k>
endmodule
