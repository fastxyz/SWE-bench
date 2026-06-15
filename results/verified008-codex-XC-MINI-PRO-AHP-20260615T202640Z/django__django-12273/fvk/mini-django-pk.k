module MINI-DJANGO-PK-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX

  syntax Val ::= "None" | Int
  syntax Next ::= "noParent" | "parent" "(" Int ")"
  syntax Stmt ::= "setPk" "(" Int "," Val ")"
                | "continue" "(" Next "," Val ")"
  syntax KResult ::= Val | Next
endmodule

module MINI-DJANGO-PK
  imports MINI-DJANGO-PK-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <attrs> .Map </attrs>
    <next> .Map </next>

  // A field id represents a Django field attname. The <next> map represents
  // the primary-key parent-link target relation:
  //   F |-> parent(G)  iff field F is a parent-link PK targeting field G.
  //   F |-> noParent   iff the chain stops at F.
  rule
    <k> setPk(F:Int, V:Val) => continue(N:Next, V) ... </k>
    <attrs> A:Map => A [F <- V] </attrs>
    <next> ... F |-> N ... </next>

  rule <k> continue(noParent, _:Val) => .K ... </k>

  rule <k> continue(parent(F:Int), V:Val) => setPk(F, V) ... </k>
endmodule
