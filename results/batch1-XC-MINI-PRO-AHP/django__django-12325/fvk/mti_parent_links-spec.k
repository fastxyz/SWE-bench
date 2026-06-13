// mti_parent_links-spec.k
// ---------------------------------------------------------------------------
// Reachability claims for the parent-link collection loop (the V1 fix).
//
//   (FOLD)        the imperative loop computes the functional fold `foldSel`.
//   (SELECT-PL)   selection correctness: for every parent key the chosen field
//                 is a parent_link whenever ANY candidate for that key is a
//                 parent_link  -- order-independently  (the bug fix, P1/P2/P3).
//
// Both are "constructed, not machine-checked" (the MVP does not run kprove).
// The list-inductive VCs for (SELECT-PL) are flagged [ESCALATION BOUNDARY] in
// fvk/PROOF.md (the bundled arithmetic tier does not discharge anyPL/candOf
// induction), with the full hand proof supplied there.
// ---------------------------------------------------------------------------

requires "mti_parent_links.k"

module MTI-PARENT-LINKS-SPEC-SYNTAX
  imports MTI-PARENT-LINKS-SYNTAX
endmodule

module VERIFICATION
  imports MTI-PARENT-LINKS-SPEC-SYNTAX
  imports MTI-PARENT-LINKS
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // ---- spec-only abstraction functions (spec vocabulary, NOT semantics) ----

  // foldSel: the pure functional model of the whole loop.
  syntax Map ::= foldSel(Map, Fields) [function, total]
  rule foldSel(M, .Fields)          => M
  rule foldSel(M, F:Field ; Rest)   => foldSel(updateSel(M, F), Rest)

  // anyPL(FS): does some field in FS carry parent_link=True ?
  syntax Bool ::= anyPL(Fields) [function, total]
  rule anyPL(.Fields)                  => false
  rule anyPL(field(_,PL,_) ; Rest)     => (PL ==Int 1) orBool anyPL(Rest)

  // candOf(FS, K): the sub-sequence of FS whose fields point at parent key K.
  syntax Fields ::= candOf(Fields, Int) [function, total]
  rule candOf(.Fields, _)              => .Fields
  rule candOf(field(K1,PL,ID) ; Rest, K) => field(K1,PL,ID) ; candOf(Rest, K)
    requires K1 ==Int K
  rule candOf(field(K1,PL,ID) ; Rest, K) => candOf(Rest, K)
    requires K1 =/=Int K

  // lastF(FS): the last field of a non-empty FS (partial on .Fields).
  syntax Field ::= lastF(Fields) [function]
  rule lastF(F:Field ; .Fields)        => F
  rule lastF(_:Field ; (G:Field ; Rest)) => lastF(G ; Rest)

  // inF(F, FS): structural membership.
  syntax Bool ::= inF(Field, Fields) [function, total]
  rule inF(_, .Fields)                 => false
  rule inF(F, G:Field ; Rest)          => (F ==K G) orBool inF(F, Rest)

  // keysOf(FS): the set of parent keys appearing in FS.
  syntax Set ::= keysOf(Fields) [function, total]
  rule keysOf(.Fields)                 => .Set
  rule keysOf(field(K,_,_) ; Rest)     => SetItem(K) keysOf(Rest)
endmodule

module MTI-PARENT-LINKS-SPEC
  imports VERIFICATION

  // (FOLD) -- the loop is the fold.  Generalised over the incoming map M and
  // the whole visit list VS; proved by guarded coinduction (induction on VS).
  // The genuine =>+ step is `select(F ; Rest) => select(Rest)`; the circularity
  // is invoked on `Rest` with the shifted map `updateSel(M, F)`.
  claim <k> select(VS:Fields) => .K ... </k>
        <plinks> M:Map => foldSel(M, VS) </plinks>
        [all-path]

  // (SELECT-PL) -- selection correctness for ONE key.  FS is the candidate
  // list of a single parent key K (every field's key is K), processed from an
  // empty slot for K.  The chosen field foldSel(.Map, FS)[K]:
  //   (I1) is one of the candidates                inF(chosen, FS)
  //   (I2) is a parent_link  IFF some candidate is  plOf(chosen)==1 <-> anyPL(FS)
  //   (I3) equals the last candidate when none is a parent_link.
  // Stated with ensures; discharged by induction on FS in fvk/PROOF.md.
  claim <k> select(FS:Fields) => .K ... </k>
        <plinks> .Map => ?M:Map </plinks>
        requires candOf(FS, keyOf(lastF(FS))) ==K FS         // FS is single-key
         andBool notBool FS ==K .Fields                      // and non-empty
        ensures  inF({?M[keyOf(lastF(FS))]}:>Field, FS)
         andBool ((plOf({?M[keyOf(lastF(FS))]}:>Field) ==Int 1) ==Bool anyPL(FS))
         andBool (notBool anyPL(FS)
                   impliesBool {?M[keyOf(lastF(FS))]}:>Field ==K lastF(FS))
        [all-path]

  // ---- arithmetic / boolean [simplification] lemmas the VCs need ----------
  // PL is a flag: every modelled field has PL in {0,1}.  (Domain fact, used to
  // collapse the biconditional case-split; discharged by Z3.)
  rule (B ==Bool true)  => B          [simplification]
  rule (false ==Bool B) => notBool B  [simplification]
endmodule
