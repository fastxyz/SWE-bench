module MINI-PARTITIONS-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX

  syntax State ::= state(Int, Map)
  syntax Out ::= out(Int, Int)
  syntax Pgm ::= collect(List) | collectSize(List)
  syntax KItem ::= emit(Map) | emitSize(Int, Map)
  syntax KResult ::= Int | Map | List | State | Out
endmodule

module MINI-PARTITIONS
  imports MINI-PARTITIONS-SYNTAX
  imports INT
  imports MAP
  imports LIST

  configuration
    <k> $PGM:Pgm </k>
    <heap> .Map </heap>
    <nextId> 0 </nextId>
    <out> .List </out>

  rule <k> collect(.List) => .K ... </k>
  rule <k> collect(ListItem(M:Map) REST:List)
        => emit(M) ~> collect(REST) ... </k>

  rule <k> collectSize(.List) => .K ... </k>
  rule <k> collectSize(ListItem(state(S:Int, M:Map)) REST:List)
        => emitSize(S, M) ~> collectSize(REST) ... </k>

  // Model Python dict.copy() at the yield boundary:
  // allocate a fresh output object id, store the current map contents there,
  // and append only that fresh id to the public output list.
  rule <k> emit(M:Map) => .K ... </k>
       <heap> H:Map => H [ ID <- M ] </heap>
       <nextId> ID:Int => ID +Int 1 </nextId>
       <out> O:List => O ListItem(ID) </out>

  rule <k> emitSize(S:Int, M:Map) => .K ... </k>
       <heap> H:Map => H [ ID <- M ] </heap>
       <nextId> ID:Int => ID +Int 1 </nextId>
       <out> O:List => O ListItem(out(S, ID)) </out>
endmodule
