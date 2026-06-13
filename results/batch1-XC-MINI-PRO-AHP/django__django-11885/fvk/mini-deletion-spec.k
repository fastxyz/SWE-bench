// fvk/mini-deletion-spec.k
// CONSTRUCTED, NOT MACHINE-CHECKED.  Reachability claims for the V1 fast-delete
// fold (the reduce(or_, ...) at the heart of Collector.related_objects).
//
// Shape imitates the sum-up reference pair (formalize.md §4–5): a LOOP
// circularity generalized over the accumulator and counter, and a function
// CONTRACT that reuses it.  The arithmetic accumulator `+` of sum-up is replaced
// by set UNION `U`; the closed form is `bigU` (the union of the field row sets).

requires "mini-deletion.k"

module MINI-DELETION-SPEC-SYNTAX
  imports MINI-DELETION-SYNTAX
endmodule

module VERIFICATION
  imports MINI-DELETION-SPEC-SYNTAX
  imports MINI-DELETION
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports INT

  // ---- spec-only abstraction functions (k-framework.md "Lists / arrays &
  //      spec-only abstraction functions"): the row-set DENOTATION of a
  //      predicate.  RowSet is an ACUI ∪-algebra; S(K) is the (uninterpreted)
  //      set of related-table rows the K-th field's FK-IN filter selects. ----
  syntax RowSet ::= "noRows"
                  | "S" "(" Int ")"
                  > RowSet "U" RowSet          [assoc, comm, left]
  syntax RowSet ::= rows ( Pred )              [function]
                  | bigU ( Int , Int )         [function]   // bigU(A,B)=S(A) U..U S(B-1)

  // ∪ is associative-commutative (declared above) + unit + idempotent:
  rule  R:RowSet U noRows => R                                       [simplification]
  rule  R:RowSet U R      => R                                       [simplification]

  // rows() is a HOMOMORPHISM  or ↦ U  — the one algebraic fact the fix relies on:
  //   combining querysets with OR unions their selected row sets.
  rule  rows(atom(K:Int))        => S(K)                             [simplification]
  rule  rows(P1:Pred or P2:Pred) => rows(P1) U rows(P2)              [simplification]

  // bigU closed form (the fold's invariant), peeled from the right and the left;
  // both directions are true of ∪ and are what the VCs need.
  rule  bigU(A:Int, B:Int) => noRows
                                requires A >=Int B                  [simplification]
  rule  bigU(A:Int, B:Int) => bigU(A, B -Int 1) U S(B -Int 1)
                                requires A  <Int B                  [simplification]
  rule  bigU(A:Int, B:Int) => S(A) U bigU(A +Int 1, B)
                                requires A  <Int B                  [simplification]
  // VC-FOLD: appending one field on the right extends the union by one index.
  rule  bigU(A:Int, I:Int) U S(I:Int) => bigU(A, I +Int 1)
                                requires A <=Int I                  [simplification]
endmodule

module MINI-DELETION-SPEC
  imports VERIFICATION

  // (FOLD) — loop circularity, generalized over accumulator A and counter I.
  // From (acc = A, i = I) the fold runs to i = N and leaves acc whose row set is
  // rows(A) extended by the union of the still-unfolded fields  I, I+1, …, N-1.
  // Soundness side condition 1 <= I <= N (counter starts at 1, never passes N+? ;
  // at I = N the body never runs and bigU(N,N) = noRows, so acc is unchanged).
  claim
    <k> while i < n { acc = acc or atom(i)  i = i + 1 } => .K ... </k>
    <store>
      acc |-> ( A:Pred => ?Acc:Pred )
      i   |-> ( I:Int  => N:Int )
      n   |-> N:Int
    </store>
    requires 1 <=Int I andBool I <=Int N
    ensures  rows(?Acc) ==K rows(A) U bigU(I, N)
    [all-path]

  // (COMBINE) — function contract for the whole reduce(or_, ...) over n >= 1
  // fields.  Returns a predicate whose row set is the union of ALL field row
  // sets:  rows(result) = S(0) U S(1) U … U S(n-1) = bigU(0, n).
  // Precondition N >= 1 is the non-empty-`related_fields` requirement (Finding
  // F4): reduce(or_, []) with no initial value is undefined.
  claim
    <k> acc = atom(0)  i = 1
        while i < n { acc = acc or atom(i)  i = i + 1 }
        return acc => .K ... </k>
    <store>
      acc |-> ( noPred => ?_:Pred )
      i   |-> ( 0      => ?_:Int  )
      n   |-> N:Int
    </store>
    <out> noPred => ?R:Pred </out>
    requires N >=Int 1
    ensures  rows(?R) ==K bigU(0, N)
    [all-path]
endmodule
