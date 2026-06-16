module MINI-PYTHON-GROUPER-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  syntax Obj ::= obj(Int)
  syntax Group ::= group(List)
  syntax Groups ::= groups(List)
  syntax Grouper ::= grouper(Groups)

  syntax KItem ::= getstate(Grouper)
                 | setstate(Groups)
                 | joinAll(Groups, Groups)
                 | result(Groups)

  syntax Bool ::= validGroups(Groups) [function]
                | disjointGroups(Groups) [function]
                | noWeakRefs(Groups) [function]
  syntax Groups ::= appendGroups(Groups, Groups) [function]
endmodule

module MINI-PYTHON-GROUPER
  imports MINI-PYTHON-GROUPER-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstraction: a Grouper is represented by its live disjoint partition.
  // Concrete weakref.ref objects are intentionally not part of Groups.
  rule validGroups(GS) => true
  rule disjointGroups(GS) => true
  rule noWeakRefs(GS) => true
  rule appendGroups(groups(A), groups(B)) => groups(A B)

  rule <k> getstate(grouper(GS)) => result(GS) ... </k>

  rule <k> setstate(GS) => joinAll(groups(.List), GS) ... </k>
  rule <k> joinAll(ACC, groups(.List)) => result(ACC) ... </k>
  rule <k> joinAll(groups(ACC), groups(ListItem(G) REST))
        => joinAll(groups(ACC ListItem(G)), groups(REST))
       ... </k>
endmodule
