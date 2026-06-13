// mini_migrations-spec.k
// =============================================================================
// Reachability claims + circularities for the V1 fix (django__django-15268).
// These are the formal statements PROOF.md discharges by construction.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP).  Emitted run-commands in PROOF.md.
// =============================================================================
requires "mini_migrations.k"

module MINI-MIGRATIONS-SPEC-SYNTAX
  imports MINI-MIGRATIONS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-MIGRATIONS-SPEC-SYNTAX
  imports MINI-MIGRATIONS
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // --- [simplification] lemmas (the verification-condition oracle) -----------

  // key is injective: two slots are equal iff same model AND same tag.
  rule { key(A:Int, B:Tag) #Equals key(C:Int, D:Tag) }
       => { A #Equals C } #And { B #Equals D }                       [simplification]

  // MAP absorption: a second write to the same key wins (overwrite semantics).
  rule M:Map [ K <- _V1 ] [ K <- V2 ] => M [ K <- V2 ]               [simplification]

  // MAP commutativity on DISTINCT keys: independent writes may be reordered.
  rule M:Map [ K1 <- V1 ] [ K2 <- V2 ] => M [ K2 <- V2 ] [ K1 <- V1 ]
    requires K1 =/=K K2                                              [simplification]
endmodule


module MINI-MIGRATIONS-SPEC
  imports VERIFICATION

  // ===========================================================================
  // PART A — the two ALGEBRAIC SOUNDNESS LAWS the fix relies on.
  //   These are the heart of the audit: every reduce() return must be backed
  //   by one of these state-transformer equalities.
  // ===========================================================================

  // (LAW-ABSORB)  Same-key ops absorb: applying O1 then O2 == applying O2 alone.
  //   Backs every  reduceB(O1, O2) == rList(O2)  (R1).
  claim applyOp(O2:Op, applyOp(O1:Op, St:Map)) => applyOp(O2, St)
    requires keyOf(O1) ==K keyOf(O2)
    [all-path]

  // (LAW-COMMUTE)  Distinct-key ops commute: order is irrelevant.
  //   Backs every  reduceB(O1, O2) == rTrue  (R2, R3).
  claim applyOp(O2:Op, applyOp(O1:Op, St:Map)) => applyOp(O1, applyOp(O2, St))
    requires keyOf(O1) =/=K keyOf(O2)
    [all-path]

  // ===========================================================================
  // PART B — reduce() CLASSIFICATION CORRECTNESS.
  //   Each claim says: the return value reduceB produces is *justified* by the
  //   actual key relationship, so PART A's law applies.  Together with the
  //   exhaustiveness of R1..R4 (a finite case split, see PROOF.md), this is the
  //   complete local-soundness obligation that the V1 fix must meet.
  // ===========================================================================

  // (RED-LIST-JUSTIFIED)  If reduce returns [O2], the two ops share a key
  //   (so LAW-ABSORB licenses dropping O1).  Reads: assuming reduce=[O2], the test
  //   keyOf(O1)==keyOf(O2) evaluates to true.
  claim <k> keyOf(O1:Op) ==K keyOf(O2:Op) => true ... </k>
    requires reduceB(O1, O2) ==K rList(O2)
    [all-path]

  // (RED-TRUE-JUSTIFIED)  If reduce returns True, the two ops have DISTINCT keys
  //   (so LAW-COMMUTE licenses reordering) — THIS IS THE FIX'S KEY OBLIGATION.
  claim <k> keyOf(O1:Op) =/=K keyOf(O2:Op) => true ... </k>
    requires reduceB(O1, O2) ==K rTrue
    [all-path]

  // ===========================================================================
  // PART C — OPTIMIZER STEP soundness + the FIXPOINT LOOP circularity.
  // ===========================================================================

  // (STEP-SOUND)  One optimizer reduction — drop an earlier op O1 absorbed by a
  //   later same-key op O2, when every op MID strictly between them commutes with
  //   O2 (allCommute) — PRESERVES the denotation applyOps, for every state St.
  //   This is the per-step verification condition; PROOF.md discharges it from
  //   LAW-ABSORB + LAW-COMMUTE.  (PRE/POST are the unchanged prefix/suffix.)
  claim applyOps((PRE:Ops O1:Op MID:Ops O2:Op POST:Ops), St:Map)
        => applyOps((PRE MID O2 POST), St)
    requires reduceB(O1, O2) ==K rList(O2)
     andBool allCommute(MID, O2)
    [all-path]

  // (OPT-LOOP)  The outer `while True:` fixpoint loop circularity.
  //   Modelled as optFix(CUR, ORIG): CUR is the current list, ORIG the original.
  //   Invariant (generalized over CUR): applyOps(CUR) == applyOps(ORIG) on every
  //   St, and length(CUR) <= length(ORIG).  K reuses this claim as its own
  //   coinduction hypothesis to discharge the recursive `operations = result`
  //   tail; the genuine =>+ step is one optimize_inner reduction (STEP-SOUND),
  //   which is also the strictly-decreasing measure (list length) that gives
  //   TERMINATION here (total, not merely partial — see PROOF.md §6).
  claim <k> optFix(CUR:Ops, ORIG:Ops) => normal(CUR) ... </k>
    requires forallStates(CUR, ORIG)            // applyOps(CUR,_) == applyOps(ORIG,_)
    ensures  forallStates(?R:Ops, ORIG)
    [all-path]

  // ===========================================================================
  // PART D — PROGRESS: the concrete issue input collapses 4 ops -> 2 ops.
  //   col is the value {("col",)} (token 1); the empty set is token 0; model m=0.
  //   Original:  aut(0,0) ait(0,0) aut(0,1) ait(0,1)   (remove∅, remove∅, add, add)
  //   Optimized: aut(0,1) ait(0,1)                      (just the two adds)
  //   This claim asserts BOTH lists denote the SAME state transformer (so the
  //   collapse is sound) AND that optimize actually reaches the 2-op normal form.
  // ===========================================================================

  // (TRACE-EQUIV)  the 4-op original and the 2-op optimized list are denotationally
  //   equal on every input state St.
  claim applyOps((aut(0,0) ait(0,0) aut(0,1) ait(0,1)), St:Map)
        => applyOps((aut(0,1) ait(0,1)), St)
    [all-path]

  // (TRACE-NORMAL)  optimize() drives the 4-op list to exactly the 2-op list.
  claim <k> optimizeAll(aut(0,0) ait(0,0) aut(0,1) ait(0,1))
            => (aut(0,1) ait(0,1)) ... </k>
    [all-path]
endmodule
