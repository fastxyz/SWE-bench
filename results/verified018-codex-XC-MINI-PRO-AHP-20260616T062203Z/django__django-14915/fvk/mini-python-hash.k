// Constructed mini semantics for the FVK audit.
// This file was not compiled or executed.

module MINI-PYTHON-HASH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Value ::= Int
                 | Obj(Int)
                 | Payload(Int)
                 | Unhashable()
                 | MCIV(Value, Value)

  syntax Query ::= hash(Value)
                 | eq(Value, Value)
                 | contains(Map, Value)
                 | get(Map, Value)

  syntax KResult ::= Int | Bool | Value
endmodule

module MINI-PYTHON-HASH
  imports MINI-PYTHON-HASH-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration <k> $PGM:Query </k>

  syntax Bool ::= hasHash(Value) [function]
  rule hasHash(_:Int) => true
  rule hasHash(Obj(_:Int)) => true
  rule hasHash(Payload(_:Int)) => true
  rule hasHash(Unhashable()) => false
  rule hasHash(MCIV(V:Value, _:Value)) => hasHash(V)

  syntax Int ::= pyHash(Value) [function]
  rule pyHash(I:Int) => I
  rule pyHash(Obj(I:Int)) => I
  rule pyHash(Payload(I:Int)) => I
  rule pyHash(MCIV(V:Value, _:Value)) => pyHash(V)

  syntax Bool ::= pyEq(Value, Value) [function]
  rule pyEq(I1:Int, I2:Int) => I1 ==Int I2
  rule pyEq(Obj(I1:Int), Obj(I2:Int)) => I1 ==Int I2
  rule pyEq(Payload(I1:Int), Payload(I2:Int)) => I1 ==Int I2
  rule pyEq(MCIV(V1:Value, _:Value), MCIV(V2:Value, _:Value)) => pyEq(V1, V2)
  rule pyEq(MCIV(V:Value, _:Value), X:Value) => pyEq(V, X) [owise]
  rule pyEq(X:Value, MCIV(V:Value, _:Value)) => pyEq(X, V) [owise]
  rule pyEq(_:Value, _:Value) => false [owise]

  rule <k> hash(V:Value) => pyHash(V) </k>
    requires hasHash(V)

  rule <k> eq(V1:Value, V2:Value) => pyEq(V1, V2) </k>

  rule <k> contains((K:Value |-> _:Value), W:Value) => true </k>
    requires hasHash(K)
     andBool hasHash(W)
     andBool pyHash(K) ==Int pyHash(W)
     andBool pyEq(K, W)

  rule <k> contains((K:Value |-> _:Value), W:Value) => false </k>
    requires hasHash(K)
     andBool hasHash(W)
     andBool (pyHash(K) =/=Int pyHash(W) orBool notBool pyEq(K, W))

  rule <k> get((K:Value |-> P:Value), W:Value) => P </k>
    requires hasHash(K)
     andBool hasHash(W)
     andBool pyHash(K) ==Int pyHash(W)
     andBool pyEq(K, W)
endmodule
