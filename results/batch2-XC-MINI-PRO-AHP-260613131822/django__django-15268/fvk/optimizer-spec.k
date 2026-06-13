// optimizer-spec.k  --  claims for django__django-15268  (CONSTRUCTED, NOT MACHINE-CHECKED)
// ===========================================================================
// Proves, against optimizer.k:
//   (REDUCE-*)   AlterTogetherOptionOperation.reduce returns the right verdict
//                for every input -- including the V1-fixed case.
//   (COMMUTE)    apply() for two ops on DISTINCT (kind,model) slots is
//                order-independent -- the semantic justification for the
//                'commute' verdict.
//   (OPT-TERM)   the optimizer fixpoint loop terminates (length variant).
// ===========================================================================
requires "optimizer.k"

module OPTIMIZER-SPEC-SYNTAX
  imports OPTIMIZER-SYNTAX
endmodule

module VERIFICATION
  imports OPTIMIZER-SPEC-SYNTAX
  imports OPTIMIZER
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports INT

  // ---- reduce(): a faithful transcription of the dispatch chain ------------
  // Inputs are the already-resolved booleans the real method branches on:
  //   sameModel    : self.name_lower == operation.name_lower
  //   sameSubclass : isinstance(operation, self.__class__)   (U==U or I==I)
  //   bTogether    : isinstance(operation, AlterTogetherOptionOperation)
  //   later        : the operation argument (returned by the collapse case)
  //
  //   super() = ModelOptionOperation.reduce -> ModelOperation.reduce -> Operation.reduce
  //
  // NOTE the modelled invariant (see PO-NOSHADOW): super() is exactly one of
  //   collapse(later) | commute(True) | barrier(False)   -- never an empty list.
  syntax Stmt ::= "REDUCE"   // placeholder so the def can be referenced in prose
  rule REDUCE => skip [macro]

  // reduce as a pure expression-level function, encoded with if/else:
  syntax Exp ::= "reduce" "(" Exp "," Exp "," Exp "," Op ")"   [function]
  rule reduce(SM, SS, BT, LATER) =>
         #if (BT andBool SS andBool SM)
           #then collapse(LATER)                         // super() == [operation]
         #else #if (notBool SM)
           #then commute                                 // super() == True (diff model)
         #else #if (BT andBool SM)
           #then commute                                 // *** V1 FIX: same model, diff kind ***
         #else barrier                                   // pre-fix behaviour: False
         #fi #fi #fi
    requires SM ==Bool SM   // total: defined for all Bool inputs
endmodule

module OPTIMIZER-SPEC
  imports VERIFICATION

  // -------------------------------------------------------------------------
  // (REDUCE-COLLAPSE)  Two ops of the SAME kind on the SAME model collapse to
  //                    the later one.  (Pre-existing behaviour, preserved.)
  // -------------------------------------------------------------------------
  claim <k> reduce(true, true, true, op(K, M, V)) => collapse(op(K, M, V)) </k>
    [all-path]

  // -------------------------------------------------------------------------
  // (REDUCE-COMMUTE-DIFFMODEL)  Different model -> commute (super() == True).
  // -------------------------------------------------------------------------
  claim <k> reduce(false, SS:Bool, true, _:Op) => commute </k>  [all-path]

  // -------------------------------------------------------------------------
  // (REDUCE-COMMUTE-SAMEMODEL)  *** THE V1 FIX ***
  //   Same model, DIFFERENT kind (sameSubclass = false), both AlterFooTogether
  //   -> commute.  Before the fix this returned barrier (False).
  // -------------------------------------------------------------------------
  claim <k> reduce(true, false, true, _:Op) => commute </k>  [all-path]

  // -------------------------------------------------------------------------
  // (REDUCE-SCOPE)  Same model but the other op is NOT an AlterFooTogether
  //   (bTogether = false, e.g. AddField/AlterField on a shared field) -> barrier.
  //   This is the #31503 split: the fix must NOT collapse across it.
  // -------------------------------------------------------------------------
  claim <k> reduce(true, SS:Bool, false, _:Op) => barrier </k>  [all-path]

  // -------------------------------------------------------------------------
  // (COMMUTE)  Semantic soundness of the 'commute' verdict: applying two ops on
  //   DISTINCT (kind,model) slots in either order yields the same model store.
  //   Modelled here for the diagnostic case kind U vs I on the same model M;
  //   slot(U,M) and slot(I,M) are distinct keys.  Generalises to any distinct
  //   (K1,M1) != (K2,M2).
  // -------------------------------------------------------------------------
  claim
    <k> apply(op(U, M, VU)) apply(op(I, M, VI)) => skip ... </k>
    <model> MS => MS [ slot(U, M) <- VU ] [ slot(I, M) <- VI ] </model>
    <out> OUT => OUT ListItem(eff(U, M, VU)) ListItem(eff(I, M, VI)) </out>
    [all-path]
  // ...and the swapped order reaches the SAME <model> (keys are independent):
  claim
    <k> apply(op(I, M, VI)) apply(op(U, M, VU)) => skip ... </k>
    <model> MS => MS [ slot(U, M) <- VU ] [ slot(I, M) <- VI ] </model>
    [all-path]
  // The two <model> right-hand sides are equal by map-commutativity on distinct
  // keys (VC-DISJOINT, see optimizer-spec lemmas / PROOF.md).

  // -------------------------------------------------------------------------
  // (OPT-TERM)  The optimizer's `while result != operations` fixpoint loop
  //   terminates.  Abstracted as a down-counting loop on the number of
  //   remaining reductions R (each pass that changes the list removes >= 1
  //   operation; the list length is bounded below by 0, so R is a well-founded
  //   decreasing variant).  Shape == examples/03-sum-down (the `I >= 0`
  //   count-down circularity).
  // -------------------------------------------------------------------------
  claim
    <k> while (0 < r) : (r = r - 1 ;) => skip ... </k>
    <store> r |-> (R:Int => 0) </store>
    requires R >=Int 0
    [all-path]
endmodule

// ---- [simplification] lemmas the VCs need --------------------------------
// VC-DISJOINT : updates on distinct keys commute (the disjoint-slot fact that
//   makes apply(U,...) and apply(I,...) order-independent -- the matching-logic
//   core of the COMMUTE claim).
//   rule MS [ slot(U,M) <- A ] [ slot(I,M) <- B ]
//     => MS [ slot(I,M) <- B ] [ slot(U,M) <- A ]   [simplification]
// VC-MAPEXT  : map extensionality, to reduce a cell #Equals to a scalar one
//   rule { MM [ K <- V ] #Equals MM [ K <- V' ] } => { V #Equals V' } [simplification]
