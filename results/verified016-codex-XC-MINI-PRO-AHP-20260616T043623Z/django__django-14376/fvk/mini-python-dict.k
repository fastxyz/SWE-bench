module MINI-PYTHON-DICT-SYNTAX
  imports STRING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Val ::= none
               | val(String)
               | intVal(Int)
               | boolVal(Bool)
               | djangoConversions
               | foundRows
               | options(Map)

  syntax Exp ::= getConnectionParams(Map)

  syntax KResult ::= Map | Val
endmodule

module MINI-PYTHON-DICT
  imports MINI-PYTHON-DICT-SYNTAX
  imports STRING
  imports INT
  imports BOOL
  imports MAP

  configuration <k> $PGM:Exp </k>

  // This mini semantics abstracts Python control flow to the map updates that
  // are observable for django__django-14376. It is intentionally small:
  // get_connection_params() has no loops and the proof obligations are map
  // key/override properties.

  syntax Map ::= baseKwargs() [function]
  rule baseKwargs()
    => "conv" |-> djangoConversions
       "charset" |-> val("utf8")
       "client_flag" |-> foundRows

  syntax Map ::= setIfPresent(Map, String, Val) [function]
  rule setIfPresent(M:Map, _K:String, none) => M
  rule setIfPresent(M:Map, K:String, V:Val) => M [K <- V]
    requires V =/=K none

  syntax Map ::= mergeOptions(Map, Map) [function]
  rule mergeOptions(M:Map, .Map) => M
  rule mergeOptions(M:Map, K:String |-> V:Val REST:Map)
    => mergeOptions(M [K <- V], REST)

  syntax Bool ::= hasKey(Map, String) [function]
  rule hasKey(.Map, _K:String) => false
  rule hasKey(K:String |-> _V:Val REST:Map, K) => true
  rule hasKey(K0:String |-> _V:Val REST:Map, K:String) => hasKey(REST, K)
    requires K0 =/=String K

  syntax Val ::= valueAt(Map, String) [function]
  rule valueAt(K:String |-> V:Val REST:Map, K) => V
  rule valueAt(K0:String |-> _V:Val REST:Map, K:String) => valueAt(REST, K)
    requires K0 =/=String K

  syntax Map ::= standardParams(Val, Val, Val, Val, Val) [function]
  rule standardParams(NAME:Val, PASSWORD:Val, none, none, none)
    => setIfPresent(
         setIfPresent(baseKwargs(), "database", NAME),
         "password",
         PASSWORD
       )

  rule
    <k>
      getConnectionParams(
        "NAME" |-> NAME:Val
        "PASSWORD" |-> PASSWORD:Val
        "USER" |-> USER:Val
        "HOST" |-> HOST:Val
        "PORT" |-> PORT:Val
        "OPTIONS" |-> options(OPTS:Map)
      )
      => mergeOptions(standardParams(NAME, PASSWORD, USER, HOST, PORT), OPTS)
    </k>
endmodule
