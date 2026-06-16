// Abstract mini semantics for Django Query.join() reuse policy.
// Constructed for FVK audit; not machine-checked in this session.

module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX
  imports SET-SYNTAX

  syntax FR ::= noFR | fr(String, String, String)
  syntax Join ::= join(String, String, String, FR)
  syntax Alias ::= String
  syntax Reuse ::= allAliases | aliases(Set)
  syntax Mode ::= normal | filteredCondition
  syntax Result ::= reuse(Alias) | create(Join)
  syntax KResult ::= Result | Bool

  syntax Bool ::= strongEq(Join, Join) [function]
                | weakEq(Join, Join) [function]
                | allowed(Alias, Reuse) [function]
  syntax Result ::= choose(Map, Join, Reuse, Mode) [function]
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL
  imports MAP
  imports SET

  configuration <k> $PGM:Result </k>

  // Strong equality is Join.__eq__(): filtered_relation participates.
  rule strongEq(join(T, P, F, FR), join(T, P, F, FR)) => true
  rule strongEq(_, _) => false [owise]

  // Weak equality is Join.equals(): filtered_relation is ignored.
  rule weakEq(join(T, P, F, _), join(T, P, F, _)) => true
  rule weakEq(_, _) => false [owise]

  rule allowed(_, allAliases) => true
  rule allowed(A, aliases(S)) => A in S

  // Specification-level abstraction of Query.join()'s reuse choice.
  // The concrete scan order is irrelevant to the issue; only existence of an
  // allowed reusable alias matters for reuse vs creation.
  rule choose((A |-> J) M, C, R, normal) => reuse(A)
    requires allowed(A, R) andBool strongEq(J, C)
  rule choose((A |-> J) M, C, R, normal) => choose(M, C, R, normal)
    requires notBool (allowed(A, R) andBool strongEq(J, C))
  rule choose((A |-> J) M, C, aliases(S), filteredCondition) => reuse(A)
    requires A in S andBool weakEq(J, C)
  rule choose((A |-> J) M, C, aliases(S), filteredCondition) =>
       choose(M, C, aliases(S), filteredCondition)
    requires notBool (A in S andBool weakEq(J, C))
  rule choose(.Map, C, _, _) => create(C)
endmodule
