// Constructed mini semantics for the admin search-query builder.
// This artifact is intentionally small and property-complete for the audited
// axis: Boolean predicate shape and number of queryset filter applications.
// It has not been compiled or machine-checked in this workspace.

module MINI-ADMIN-SEARCH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX

  syntax Lookup ::= lookup(String)
  syntax Term ::= term(String)
  syntax QAtom ::= atom(Lookup, Term)
  syntax QExpr ::= qtrue
                 | qatom(QAtom)
                 | qor(List)
                 | qand(List)

  syntax Result ::= result(QExpr, Int, Bool)
  syntax AdminSearch ::= adminSearch(List, List, Bool) | Result
  syntax KResult ::= Result
endmodule

module MINI-ADMIN-SEARCH
  imports MINI-ADMIN-SEARCH-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:AdminSearch </k>

  syntax List ::= atomsFor(List, Term) [function]
  syntax List ::= clausesFor(List, List) [function]

  rule atomsFor(.List, T:Term) => .List
  rule atomsFor(ListItem(L:Lookup) LS:List, T:Term)
    => ListItem(qatom(atom(L, T))) atomsFor(LS, T)

  rule clausesFor(.List, LS:List) => .List
  rule clausesFor(ListItem(T:Term) TS:List, LS:List)
    => ListItem(qor(atomsFor(LS, T))) clausesFor(TS, LS)

  syntax Bool ::= isEmpty(List) [function]
  rule isEmpty(.List) => true
  rule isEmpty(ListItem(_) _:List) => false

  // Duplicates are supplied as the third argument, representing the unchanged
  // result of any(lookup_spawns_duplicates(...)).
  rule <k> adminSearch(LS:List, TS:List, DUP:Bool)
        => result(qtrue, 0, DUP)
       </k>
    requires isEmpty(TS)

  rule <k> adminSearch(LS:List, TS:List, DUP:Bool)
        => result(qand(clausesFor(TS, LS)), 1, DUP)
       </k>
    requires notBool isEmpty(TS)
endmodule
