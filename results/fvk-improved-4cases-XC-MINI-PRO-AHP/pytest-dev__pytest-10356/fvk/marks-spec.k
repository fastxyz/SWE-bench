// marks-spec.k — K reachability claims for get_unpacked_marks' MRO mark
// collection (the V2 fix). Proves the *flattening loop* concatenates every
// per-class mark list, in MRO order, losing none (the bug was that marks of
// all-but-one base class were lost).
//
// Run (constructed, NOT machine-checked in this MVP):
//   kompile mini-python.k --backend haskell
//   kast    --backend haskell marks-spec.k
//   kprove  marks-spec.k                       # expected: #Top

requires "mini-python.k"

module MARKS-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
endmodule

module VERIFICATION
  imports MARKS-SPEC-SYNTAX
  imports MINI-PYTHON
  imports LIST
  imports INT
  imports K-EQUAL

  // ---- spec-only abstraction: in-order concatenation of mark lists -------
  // concatFrom(LL, I) = LL[I] ++ LL[I+1] ++ ... ++ LL[size(LL)-1]
  // where LL is the list of per-class mark lists in MRO (most-derived-first)
  // order, and each LL[k] is itself a List of marks. This plays the role of the
  // loop's closed form (cf. the running sum in the sum example).
  syntax List ::= concatFrom(List, Int) [function]
  rule concatFrom(LL:List, I:Int) => .List
       requires I >=Int size(LL)                                    [simplification]
  rule concatFrom(LL:List, I:Int) => {LL[I]}:>List concatFrom(LL, I +Int 1)
       requires 0 <=Int I andBool I <Int size(LL)                   [simplification]

  // membership / sublist helper used to state completeness in English (F-LEDGER);
  // contains(LL, I) is true iff every element of LL[I] appears in concatFrom(LL,0).
  // (Stated for documentation; its inductive discharge is the escalation boundary.)
endmodule

module MARKS-SPEC
  imports VERIFICATION

  // ====================================================================
  // (CONCAT) — the loop circularity.
  // Generalized over accumulator ML and counter I (NOT pinned to [] / 0).
  // Running the loop from i=I, mark_list=ML appends concatFrom(mark_lists, I)
  // and leaves i = size(mark_lists).
  // SPEC-PROVENANCE:
  // - from_prompt: "pytest should walk the mro of a class to get all markers"
  //                => the loop must visit EVERY entry of mark_lists (i runs
  //                   0..size), concatenating each — none skipped (completeness).
  // - from_prompt: bluetech REPL "C.pytestmark ... (b is missing)" => the BUG is
  //                that the old code visited only ONE mro entry; the side
  //                condition I <= size(ML) and the [all-path] full traversal are
  //                exactly what rules that out.
  // - from_code:  while i < len(mark_lists): mark_list = mark_list + mark_lists[i]; i += 1
  // - soundness side condition: 0 <= I <= size(mark_lists)  (without the upper
  //                bound the post-state i = size is unreachable; without 0<=I the
  //                element reads are out of range).
  // ====================================================================
  claim
    <k> while i < len ( ml ) :
          mark_list = mark_list + ml [ i ]
          i = i + 1
        => .K ... </k>
    <store>
      ml        |-> ML:List
      mark_list |-> (ACC:List => ACC concatFrom(ML, I))
      i         |-> (I:Int    => size(ML))
    </store>
    requires 0 <=Int I andBool I <=Int size(ML)
    [all-path]

  // ====================================================================
  // (GUM) — the function contract.
  //   get_unpacked_marks(ML)  ==>  concatFrom(ML, 0)
  // i.e. the result is exactly mark_lists[0] ++ mark_lists[1] ++ ... in MRO order.
  // SPEC-PROVENANCE:
  // - from_prompt: "I'd expect foo and bar to be markers for test_dings" and
  //                maintainer-confirmed "marks of test_d should be
  //                [Mark(name=mark1), Mark(name=mark4)]" => result contains the
  //                marks of ALL classes in the MRO (completeness), in MRO order
  //                (most-derived first; for class C(A,B): C, then A, then B).
  // - from_code:  mark_lists = [x.__dict__.get("pytestmark", []) for x in obj.__mro__]
  //                => ML is in forward MRO order; GUM returns their concatenation.
  // - completeness corollary: concatFrom(ML,0) = ML[0] ++...++ ML[n-1], so for
  //                every k, ML[k] is a contiguous sublist of the result => no
  //                class's marks are dropped. This is the property the V1 (buggy
  //                upstream) code violated.
  // ====================================================================
  claim
    <k> def get_unpacked_marks ( marklists ) :
          mark_list = empty
          i = zero
          while i < len ( marklists ) :
            mark_list = mark_list + marklists [ i ]
            i = i + 1
          return mark_list
        ~> call get_unpacked_marks ( ML:List )
        => .K ... </k>
    <store> STORE => ?_:Map </store>
    <funcs> _ => ?_:Map </funcs>
    <stack> .List </stack>
    <out>  ( .K => concatFrom(ML, 0) ) </out>
    requires notBool (get_unpacked_marks in_keys(STORE))
    ensures true
    [all-path]

  // `empty` and `zero` are sugar for the literals [] and 0 in the def body;
  // declared here so the claim program parses against the mini-Python syntax.
  syntax Exp ::= "empty" [macro] | "zero" [macro]
  rule empty => .List
  rule zero  => 0
endmodule
