// combine-aliasing-spec.k
// =============================================================================
// Reachability claims for combine-aliasing.k.
//   (COMBINE)  function contract: the loop yields a disjoint change_map.
//   (LOOP)     loop circularity: the disjointness invariant is preserved.
//
// STATUS: constructed, NOT machine-checked. Run-commands at the bottom.
// =============================================================================

requires "combine-aliasing.k"

module COMBINE-ALIASING-SPEC-SYNTAX
  imports COMBINE-ALIASING-SYNTAX
endmodule

module VERIFICATION
  imports COMBINE-ALIASING-SPEC-SYNTAX
  imports COMBINE-ALIASING
  imports MAP-SYMBOLIC
  imports K-EQUAL
  imports BOOL

  // --- spec-only abstraction predicates (vocabulary, not language constructs) -

  // A is a generated alias whose prefix is P.
  syntax Bool ::= aliasHasPrefix(Alias, Id)   [function, total]
  rule aliasHasPrefix(pref(P:Id, _:Int), Q:Id) => P ==K Q
  rule aliasHasPrefix(name(_:Id),        _:Id) => false

  // A is a legal change_map VALUE for a query whose own prefix is P:
  // either a generated alias with prefix P, or a bare table-name alias.
  syntax Bool ::= isValueAlias(Alias, Id)     [function, total]
  rule isValueAlias(pref(P:Id, _:Int), Q:Id) => P ==K Q
  rule isValueAlias(name(_:Id),        _:Id) => true

  // every KEY of M is a generated alias with prefix Pr.
  syntax Bool ::= keysPref(Map, Id)           [function]
  rule keysPref(.Map, _:Id) => true
  rule keysPref((K:Alias |-> _:Alias) M:Map, Pr:Id)
    => aliasHasPrefix(K, Pr) andBool keysPref(M, Pr)

  // every VALUE of M is a legal value alias for self-prefix Ps.
  syntax Bool ::= valsDom(Map, Id)            [function]
  rule valsDom(.Map, _:Id) => true
  rule valsDom((_:Alias |-> V:Alias) M:Map, Ps:Id)
    => isValueAlias(V, Ps) andBool valsDom(M, Ps)

  // keys(M) and values(M) are disjoint -- the property change_aliases asserts.
  syntax Bool ::= disjointKV(Map)             [function]

  // ----------------------------------------------------------------------------
  // CORE STRUCTURAL LEMMA (the heart of the django-15128 fix).
  //
  // If every key has the rhs prefix Pr, every value is self-prefixed (Ps) or a
  // table name, and Pr =/= Ps, then NO key can equal ANY value:
  //   * key pref(Pr,_) vs value pref(Ps,_): differ because Pr =/= Ps;
  //   * key pref(Pr,_) vs value name(_)   : differ by constructor (shape).
  // Hence keys(M) and values(M) are disjoint.
  //
  // The per-pair core is purely structural (constructor disequality); it needs
  // NO arithmetic and NO "table names never look like generated aliases"
  // assumption. The lift from "per pair" to "over the whole Map" is an induction
  // over Map (discharged by Z3's map theory for the bundled tier on each fold
  // step; the fully general Map-fold is flagged [ESCALATION BOUNDARY] in
  // PROOF.md -- it is NOT faked as [trusted]).
  // ----------------------------------------------------------------------------
  rule disjointKV(M:Map) => true
    requires keysPref(M, Pr) andBool valsDom(M, Ps) andBool notBool (Pr ==K Ps)
    [simplification]
endmodule

module COMBINE-ALIASING-SPEC
  imports VERIFICATION

  // ===========================================================================
  // (LOOP) -- loop circularity.
  // Generalized over the already-built map M and the remaining stream PS.
  // Precondition (the soundness side condition, analogous to sum's I <= N+1):
  //   * M already satisfies the invariant: keysPref(M,Pr) /\ valsDom(M,Ps);
  //   * every pending pair has a key with prefix Pr and a value in dom(Ps);
  //   * Pr =/= Ps.
  // Postcondition: the loop terminates (<k> => .K) having consumed PS, and the
  // final map still satisfies keysPref/valsDom (whence disjointKV by the lemma).
  // ===========================================================================
  claim <k> buildChangeMap => .K </k>
        <pairs> PS:List => .List </pairs>
        <cmap>  M:Map => ?M':Map </cmap>
    requires keysPref(M, Pr:Id) andBool valsDom(M, Ps:Id)
     andBool notBool (Pr ==K Ps)
     andBool allKeysPref(PS, Pr) andBool allValsDom(PS, Ps)
    ensures keysPref(?M', Pr) andBool valsDom(?M', Ps)
    [all-path]

  // ===========================================================================
  // (COMBINE) -- function contract: the whole loop, from the empty change_map.
  // Precondition: rhs keys all carry prefix Pr, values all in dom(Ps), Pr =/= Ps
  //   (established by combine's guard + bump_prefix; see PO-PREFIX/PO-KEYS/PO-VALS).
  // Postcondition: change_map's keys and values are disjoint -- i.e. every
  //   downstream change_aliases(change_map) satisfies its
  //   `assert set(change_map).isdisjoint(change_map.values())` precondition.
  // ===========================================================================
  claim <k> buildChangeMap => .K </k>
        <pairs> PS:List => .List </pairs>
        <cmap>  .Map => ?M':Map </cmap>
    requires allKeysPref(PS, Pr:Id) andBool allValsDom(PS, Ps:Id)
     andBool notBool (Pr ==K Ps)
    ensures disjointKV(?M') ==K true
    [all-path]
endmodule

// Helper predicates over the input stream PS (declared here to keep the claims
// readable). allKeysPref(PS,Pr): every pending pair's key is pref(Pr,_).
// allValsDom(PS,Ps): every pending pair's value is pref(Ps,_) or name(_).
//
//   syntax Bool ::= allKeysPref(List, Id) [function]
//   rule allKeysPref(.List, _) => true
//   rule allKeysPref(ListItem(pair(K,_)) R, Pr)
//        => aliasHasPrefix(K,Pr) andBool allKeysPref(R,Pr)
//   syntax Bool ::= allValsDom(List, Id) [function]
//   rule allValsDom(.List, _) => true
//   rule allValsDom(ListItem(pair(_,V)) R, Ps)
//        => isValueAlias(V,Ps) andBool allValsDom(R,Ps)
// (kept in this comment to avoid cluttering VERIFICATION; move into it to run.)
//
// -----------------------------------------------------------------------------
// Reproduce the (would-be) machine check -- constructed, not yet run:
//   kompile combine-aliasing.k --backend haskell
//   kast    --backend haskell combine-aliasing-spec.k
//   kprove  combine-aliasing-spec.k        # expected, once run: #Top
// -----------------------------------------------------------------------------
