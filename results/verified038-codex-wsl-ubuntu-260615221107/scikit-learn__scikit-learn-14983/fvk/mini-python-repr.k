module MINI-PYTHON-REPR-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Value ::= intVal(Int) | noneVal

  syntax Keys ::= ".Keys" | key(String) Keys
  syntax Pairs ::= ".Pairs" | pair(String, Value) Pairs
  syntax Obj ::= obj(String, Keys, Pairs, Pairs)

  syntax Exp ::= reprRepeated(Obj)
               | buildRepr(Obj)
               | resolve(String, Pairs, Pairs)
               | resolveCv(String, Pairs)
               | collect(Keys, Pairs, Pairs)
               | format(String, Pairs)

  syntax KResult ::= String | Value | Pairs
endmodule

module MINI-PYTHON-REPR
  imports MINI-PYTHON-REPR-SYNTAX
  imports INT
  imports STRING
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> reprRepeated(O:Obj) => buildRepr(O) ... </k>

  rule <k> buildRepr(obj(C:String, KS:Keys, ATTRS:Pairs, CVARGS:Pairs))
        => C +String "(" +String format(C, collect(KS, ATTRS, CVARGS)) +String ")" ... </k>

  syntax Pairs ::= collect(Keys, Pairs, Pairs) [function]
  rule collect(.Keys, ATTRS, CVARGS) => .Pairs
  rule collect(key(K:String) KS:Keys, ATTRS:Pairs, CVARGS:Pairs)
    => pair(K, resolve(K, ATTRS, CVARGS)) collect(KS, ATTRS, CVARGS)

  syntax Value ::= resolve(String, Pairs, Pairs) [function]
  rule resolve(K:String, pair(K, V:Value) REST:Pairs, CVARGS:Pairs) => V
  rule resolve(K:String, pair(K2:String, V:Value) REST:Pairs, CVARGS:Pairs)
    => resolve(K, REST, CVARGS)
    requires K =/=String K2
  rule resolve(K:String, .Pairs, CVARGS:Pairs) => resolveCv(K, CVARGS)

  syntax Value ::= resolveCv(String, Pairs) [function]
  rule resolveCv(K:String, pair(K, V:Value) REST:Pairs) => V
  rule resolveCv(K:String, pair(K2:String, V:Value) REST:Pairs)
    => resolveCv(K, REST)
    requires K =/=String K2
  rule resolveCv(K:String, .Pairs) => noneVal

  syntax String ::= valRepr(Value) [function]
  rule valRepr(intVal(I:Int)) => Int2String(I)
  rule valRepr(noneVal) => "None"

  syntax String ::= format(String, Pairs) [function]
  rule format(C:String,
      pair("n_repeats", NR:Value)
      pair("n_splits", NS:Value)
      pair("random_state", RS:Value)
      .Pairs)
    => "n_repeats=" +String valRepr(NR)
       +String ", n_splits=" +String valRepr(NS)
       +String ", random_state=" +String valRepr(RS)
    requires C ==String "RepeatedKFold" orBool C ==String "RepeatedStratifiedKFold"

  rule format(C:String, pair(K:String, V:Value) .Pairs)
    => K +String "=" +String valRepr(V)
    requires notBool (C ==String "RepeatedKFold" orBool C ==String "RepeatedStratifiedKFold")
endmodule

