module MINI-REQUESTS-MERGE-SYNTAX
  imports MAP-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Val ::= noneVal | value(String)
  syntax Setting ::= absent | scalar(Val) | mapping(Map)
  syntax Exp ::= mergeSetting(Setting, Setting)

  syntax Map ::= overlay(Map, Map) [function]
               | filterNone(Map) [function]
  syntax Bool ::= keyIn(String, Map) [function]

  syntax KResult ::= Setting
endmodule

module MINI-REQUESTS-MERGE
  imports MINI-REQUESTS-MERGE-SYNTAX
  imports MAP
  imports STRING
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Python-level None for a whole setting, matching the early returns.
  rule <k> mergeSetting(REQ:Setting, absent) => REQ ... </k>
  rule <k> mergeSetting(absent, SES:Setting) => SES ... </k>

  // Non-mapping settings bypass dictionary merging and use the request value.
  rule <k> mergeSetting(scalar(REQ:Val), scalar(_SES:Val)) => scalar(REQ) ... </k>
  rule <k> mergeSetting(scalar(REQ:Val), mapping(_SES:Map)) => scalar(REQ) ... </k>
  rule <k> mergeSetting(mapping(REQ:Map), scalar(_SES:Val)) => mapping(REQ) ... </k>

  // Mapping settings: session values first, request values override, then
  // final None values are omitted from the merged result.
  rule <k> mergeSetting(mapping(REQ:Map), mapping(SES:Map))
        => mapping(filterNone(overlay(SES, REQ))) ... </k>

  // overlay(BASE, UPDATES) copies BASE then applies UPDATES.
  rule overlay(BASE:Map, .Map) => BASE
  rule overlay(BASE:Map, (K:String |-> V:Val) REST:Map)
    => overlay(BASE [K <- V], REST)

  // filterNone removes keys whose final merged value is noneVal.
  rule filterNone(.Map) => .Map
  rule filterNone((K:String |-> noneVal) REST:Map) => filterNone(REST)
  rule filterNone((K:String |-> V:Val) REST:Map)
    => filterNone(REST) [K <- V]
    requires V =/=K noneVal

  rule keyIn(_K:String, .Map) => false
  rule keyIn(K:String, (K |-> _V:Val) _REST:Map) => true
  rule keyIn(K:String, (_K2:String |-> _V:Val) REST:Map) => keyIn(K, REST) [owise]
endmodule

