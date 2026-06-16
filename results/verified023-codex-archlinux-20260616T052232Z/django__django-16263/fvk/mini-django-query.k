module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL
  imports INT
  imports MAP
  imports SET

  syntax QueryOp ::= addAnnotation(Id, Expr)
                   | solveLookup(Path)
                   | prune(Bool, Bool)
                   | getCount
                   | exists
  syntax KItem ::= "countWithoutPrune"
                 | "countAfterPrune"
                 | "existsWithoutTopLevelPrune"
                 | "existsAfterPrune"
  syntax Id ::= String
  syntax Expr ::= "expr" | "nonAggregateMultiValued" | "aggregate"
  syntax Path ::= String
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL
  imports INT
  imports MAP
  imports SET

  configuration
    <k> $PGM:K </k>
    <annotations> .Map </annotations>
    <selected> .Set </selected>
    <deps> .Map </deps>
    <lookupRefs> .Set </lookupRefs>
    <aliasDelta> .Map </aliasDelta>
    <aliasRefcount> .Map </aliasRefcount>
    <groupBy> "none" </groupBy>
    <distinct> false </distinct>
    <distinctFields> .Set </distinctFields>
    <sliced> false </sliced>
    <combinator> false </combinator>

  // Abstract semantic hooks. The proof obligations in
  // query-prune-spec.k constrain these hooks; this scaffold records the
  // intended state shape without modeling Django's full SQL compiler.
  syntax Set ::= requiredRoots(Map, Set, Set, Set, Bool, Bool) [function]
  syntax Set ::= closure(Set, Map) [function]
  syntax Set ::= keys(Map) [function]
  syntax Map ::= restrict(Map, Set) [function]
  syntax Map ::= subtractDeltas(Map, Map, Set) [function]
  syntax Bool ::= prefix(Id, Path) [function]
  syntax Id ::= annotationPrefix(Path, Map) [function]
  syntax Map ::= positiveDelta(Map, Map) [function]
endmodule
