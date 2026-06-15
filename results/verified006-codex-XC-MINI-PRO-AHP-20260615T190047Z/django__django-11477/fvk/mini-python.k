module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Value ::= "None"
                 | "int" "(" Int ")"
                 | "str" "(" String ")"
                 | "bool" "(" Bool ")"

  syntax Values ::= ".Values"
                  | Value Values [right]

  syntax Stmt ::= "normalizeArgs" "(" Values ")"
                | "normalizeKwargs" "(" Map ")"

  syntax KResult ::= Values | Map
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports MAP
  imports K-EQUAL

  configuration <k> $PGM:Stmt </k>

  syntax Values ::= dropNoneArgs(Values) [function]
  rule dropNoneArgs(.Values) => .Values
  rule dropNoneArgs(None VS:Values) => dropNoneArgs(VS)
  rule dropNoneArgs(V:Value VS:Values) => V dropNoneArgs(VS)
    requires V =/=K None

  syntax Map ::= dropNoneKwargs(Map) [function]
  rule dropNoneKwargs(.Map) => .Map
  rule dropNoneKwargs((K:Id |-> None) REST:Map) => dropNoneKwargs(REST)
  rule dropNoneKwargs((K:Id |-> V:Value) REST:Map) => (K |-> V) dropNoneKwargs(REST)
    requires V =/=K None

  rule <k> normalizeArgs(VS:Values) => dropNoneArgs(VS) </k>
  rule <k> normalizeKwargs(KWS:Map) => dropNoneKwargs(KWS) </k>
endmodule

