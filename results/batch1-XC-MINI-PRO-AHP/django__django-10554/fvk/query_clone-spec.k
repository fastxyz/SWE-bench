// Claims for the V1 fix (Query.clone() deep-copies combined_queries).
// Constructed, NOT machine-checked (MVP: no kompile/kprove run here).

requires "query_clone.k"

module QUERY-CLONE-SPEC-SYNTAX
  imports QUERY-CLONE-SYNTAX
endmodule

module VERIFICATION
  imports QUERY-CLONE-SPEC-SYNTAX
  imports QUERY-CLONE
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports SET

  // ---- spec-only abstraction: the reachable object-id set --------------------
  // reach(OBJS, I) = least set with I and closed under the `comb` edges.
  // (Inductive / least-fixpoint predicate -- matching-mu-logic; see
  //  matching-logic.md §5.  Discharging VCs over it is an ESCALATION BOUNDARY,
  //  see PROOF.md.)
  syntax Set ::= reach(Map, Int)            [function]
               | reachL(Map, List)          [function]
  rule reach(OBJS, I) => SetItem(I) reachL(OBJS, Comb(OBJS, I))
  rule reachL(_, .List) => .Set
  rule reachL(OBJS, ListItem(C:Int) REST) => reach(OBJS, C) reachL(OBJS, REST)
  syntax List ::= Comb(Map, Int)            [function]
  rule Comb(OBJS, I) => COMB requires OBJS [ I ] ==K obj(_, COMB) [owise]
endmodule

module QUERY-CLONE-SPEC
  imports VERIFICATION

  // (CLONE-REC)  The recursion circularity: clone of a well-formed, acyclic
  // object graph rooted at R terminates in a fresh root ?R whose reachable id
  // set is DISJOINT from the source graph's, and is made entirely of ids that
  // did not exist before the call (>= the allocator value N0).
  //
  //   pre : R is a key of OBJS; the comb-graph under R is finite and acyclic;
  //         every id in reach(OBJS,R) is < N0 (allocator high-water mark).
  //   post: a fresh ?R is returned; the heap grows by exactly reach's-worth of
  //         fresh objects; reach(OBJS',?R) ∩ reach(OBJS,R) = .Set, and every id
  //         in reach(OBJS',?R) is >= N0.
  claim
    <k> clone(R:Int) => ?R:Int ... </k>
    <objs> OBJS => OBJS ?FRESH:Map </objs>
    <next> N0:Int => ?N1:Int </next>
    requires R in_keys(OBJS)
     andBool acyclic(OBJS, R)
     andBool allBelow(reach(OBJS, R), N0)
    ensures  (?R >=Int N0)
     andBool (keys(?FRESH) ==K reach(OBJS ?FRESH, ?R))
     andBool (allAtLeast(reach(OBJS ?FRESH, ?R), N0))
     andBool (intersectSet(reach(OBJS ?FRESH, ?R), reach(OBJS, R)) ==K .Set)
    [all-path]

  // (CLONE-ISO)  The whole-fix isolation contract, derived from (CLONE-REC):
  // after `c = clone(q)` the object graphs of `c` and `q` share NO object id,
  // so a later in-place setvals() on any node of `c`'s graph leaves every node
  // of `q`'s graph unchanged.  This is the non-interference the bug needs.
  //
  //   q = R0 (a union with combined queries); c = clone(R0); then for any V and
  //   any id M reachable from c, setvals(M,V) does not change colsOf(R0) nor any
  //   colsOf of an id reachable from R0.
  claim
    <k> c = clone(q) ; setvals(M, V) => .K ... </k>
    <store> ... q |-> R0:Int  c |-> (?_ => ?C:Int) ... </store>
    <objs> OBJS => ?OBJS:Map </objs>
    <next> N0:Int => ?_:Int </next>
    requires R0 in_keys(OBJS)
     andBool acyclic(OBJS, R0)
     andBool allBelow(reach(OBJS, R0), N0)
     andBool (M in reach(?dummyAfterClone(OBJS, R0, N0)))   // M is in c's graph
    // every object reachable from R0 keeps the cols it had in OBJS:
    ensures  preservedOn(reach(OBJS, R0), OBJS, ?OBJS)
    [all-path]

  // ----- spec-only helper predicates (declared; their inductive theory is the
  //        escalation boundary, discharged structurally in PROOF.md) -----------
  syntax Bool ::= acyclic(Map, Int)            [function]
                | allBelow(Set, Int)           [function]
                | allAtLeast(Set, Int)         [function]
                | preservedOn(Set, Map, Map)   [function]
                | Int "in" Set                 [function]
  syntax Set  ::= intersectSet(Set, Set)       [function]
  syntax Set  ::= "?dummyAfterClone" "(" Map "," Int "," Int ")" [function]
endmodule
