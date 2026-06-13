// mini-X (mini-Python) K fragment for the V1 fix to django__django-10554.
//
// We are NOT formalizing arithmetic; we are formalizing an OBJECT-ALIASING
// property of `Query.clone()`. The fragment models exactly the constructs the
// fix and its neighbours use:
//
//   * a heap of mutable `Query` objects, each carrying
//       - `cols`  : the selected-column list (what set_values() resets), and
//       - `comb`  : the list of *references* (ids) to its combined queries;
//   * `clone(o)`   : allocate a FRESH object, copy `cols`, and (V1 fix)
//                    set `comb := [clone(c) for c in o.comb]`  -- a recursive
//                    deep copy of the combined-query references;
//   * `setvals(o,v)`: the in-place mutation done during compilation
//                    (get_combinator_sql -> set_values): `o.cols := v`.
//
// `clone` is a RECURSIVE function, so its contract is proved by the recursion
// circularity (see reachability-and-circularities.md §3, the (REC) recipe).
//
// MVP stopgap: this is a deliberately minimal fragment. The heap is an explicit
// `<objs>` Map (object id -> obj(cols, comb)); object identity is the integer
// id. Real Python object identity / GC is abstracted to fresh integer ids from
// a `<next>` counter. Faithfulness of this abstraction is part of the trusted
// base (see PROOF.md, Residual risk).

module QUERY-CLONE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  // Expressions evaluate to an Int (an object id) or a List (a cols/comb list).
  syntax Exp ::= Int | Id | List
               | "clone" "(" Exp ")"            [strict]
               | "setvals" "(" Exp "," Exp ")"  [seqstrict]
               | "combOf" "(" Exp ")"           [strict]   // read o.comb
               | "colsOf" "(" Exp ")"           [strict]   // read o.cols

  syntax Stmt ::= Id "=" Exp ";"               [strict(2)]
                | Stmt Stmt                      [left]

  syntax KResult ::= Int | List
endmodule

module QUERY-CLONE
  imports QUERY-CLONE-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST

  // obj(Cols, Comb): Cols is the column list; Comb is the list of child ids.
  syntax Obj ::= obj(List, List)

  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>          // program variable Id |-> object id (Int)
    <objs>  .Map </objs>           // heap: object id (Int) |-> Obj
    <next>  0:Int </next>          // fresh-id allocator

  // ---- variables -------------------------------------------------------------
  rule <k> X:Id => I ... </k> <store> ... X |-> I:Int ... </store>
  rule <k> X:Id = I:Int ; => .K ... </k>
       <store> STORE => STORE [ X <- I ] </store>

  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- field reads -----------------------------------------------------------
  rule <k> colsOf(I:Int) => COLS ... </k> <objs> ... I |-> obj(COLS, _) ... </objs>
  rule <k> combOf(I:Int) => COMB ... </k> <objs> ... I |-> obj(_, COMB) ... </objs>

  // ---- setvals : the in-place column reset done during compilation -----------
  // Models get_combinator_sql -> Query.set_values(): it REBINDS o.cols in place,
  // so every alias of object `I` observes the change (this is exactly the bug
  // mechanism when `I` is shared between two querysets).
  rule <k> setvals(I:Int, V:List) => I ... </k>
       <objs> ... I |-> (obj(_, COMB) => obj(V, COMB)) ... </objs>

  // ---- clone : the function under audit (V1 fix) -----------------------------
  // clone(I) allocates a fresh id N, copies cols, and recursively clones each
  // combined-query id.  `cloneList` is the `tuple(q.clone() for q in comb)`.
  rule <k> clone(I:Int) => cloneObj(I, COLS, COMB) ... </k>
       <objs> ... I |-> obj(COLS, COMB) ... </objs>

  syntax Exp ::= cloneObj(Int, List, List)        [strict(3)]
               | cloneList(List)                   [strict]
               | allocClone(List, List)

  // first deep-clone the children list, then allocate the new object
  rule <k> cloneObj(_I, COLS, COMB) => allocClone(COLS, cloneList(COMB)) ... </k>
  rule <k> allocClone(COLS, COMB:List) => N ... </k>
       <objs> OBJS => OBJS [ N <- obj(COLS, COMB) ] </objs>
       <next> N:Int => N +Int 1 </next>
       requires notBool (N in_keys(OBJS))

  // cloneList([c0, c1, ...]) = [clone(c0), clone(c1), ...]
  rule <k> cloneList(.List) => .List ... </k>
  rule <k> cloneList(ListItem(C:Int) REST)
        => appendClone(clone(C), cloneList(REST)) ... </k>
  syntax Exp ::= appendClone(Exp, Exp)            [seqstrict]
  rule <k> appendClone(I:Int, L:List) => ListItem(I) L ... </k>
endmodule
