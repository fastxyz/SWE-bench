module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX

  syntax Decision ::= "Wrapped" | "Direct"
  syntax SqlShape ::= "SafeOuterAlias" | "InvalidNestedWindow" | "PlainAggregate"

  syntax KItem ::= "aggregateDecision" "(" Bool "," Bool "," Bool "," Bool "," Bool "," Bool "," Bool "," Bool ")"
                 | "aggregateSqlShape" "(" Bool "," Bool "," Bool "," Bool "," Bool "," Bool "," Bool "," Bool ")"
                 | "compileAfterDecision" "(" Bool ")"
                 | "compileAggregate" "(" Decision "," Bool ")"

  syntax KResult ::= Decision | SqlShape
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration <k> $PGM:KItem </k>

  rule <k> aggregateDecision(GB:Bool, SL:Bool, HEA:Bool, RS:Bool, RW:Bool, Q:Bool, DS:Bool, CB:Bool)
        => Wrapped ... </k>
    requires (((((((GB orBool SL) orBool HEA) orBool RS) orBool RW) orBool Q) orBool DS) orBool CB)

  rule <k> aggregateDecision(GB:Bool, SL:Bool, HEA:Bool, RS:Bool, RW:Bool, Q:Bool, DS:Bool, CB:Bool)
        => Direct ... </k>
    requires notBool (((((((GB orBool SL) orBool HEA) orBool RS) orBool RW) orBool Q) orBool DS) orBool CB)

  rule <k> aggregateSqlShape(GB:Bool, SL:Bool, HEA:Bool, RS:Bool, RW:Bool, Q:Bool, DS:Bool, CB:Bool)
        => aggregateDecision(GB, SL, HEA, RS, RW, Q, DS, CB) ~> compileAfterDecision(RW) ... </k>

  rule <k> D:Decision ~> compileAfterDecision(RW:Bool) => compileAggregate(D, RW) ... </k>

  rule <k> compileAggregate(Wrapped, true) => SafeOuterAlias ... </k>
  rule <k> compileAggregate(Direct, true) => InvalidNestedWindow ... </k>
  rule <k> compileAggregate(_:Decision, false) => PlainAggregate ... </k>
endmodule
