// Constructed for FVK audit of django__django-11299.
// Status: constructed, not machine-checked.

module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX

  // A reduced model of the only structure relevant to the defect:
  // a finite Q tree whose leaves are lookup filters and whose internal nodes
  // are nested Q objects.
  syntax QTree ::= leaf
                 | node(QTree, QTree)

  // Observable column-rendering mode at each lookup leaf.
  syntax ModeTree ::= simpleLeaf
                    | colLeaf
                    | nodeM(ModeTree, ModeTree)

  syntax Exp ::= ModeTree
               | compile(QTree, Bool)
               | nodeM(Exp, Exp) [seqstrict]

  syntax KResult ::= ModeTree
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Direct lookup children are compiled by build_filter(..., simple_col=S).
  rule <k> compile(leaf, true) => simpleLeaf ... </k>
  rule <k> compile(leaf, false) => colLeaf ... </k>

  // Nested Q nodes must preserve the incoming simple_col flag for each child.
  rule <k> compile(node(L:QTree, R:QTree), S:Bool)
        => nodeM(compile(L, S), compile(R, S)) ... </k>
endmodule
