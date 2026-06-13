// schema_index-spec.k — reachability claims for the constraint-resolution fragment.
// CONSTRUCTED, NOT MACHINE-CHECKED (no kompile/kprove in this environment).
//
// Run-commands that WOULD machine-check these (roadmap):
//   kompile schema_index.k --backend haskell
//   kast    --backend haskell schema_index-spec.k
//   kprove  schema_index-spec.k          # expected: #Top  (all claims proved)

requires "schema_index.k"

module SCHEMA-INDEX-SPEC-SYNTAX
  imports SCHEMA-INDEX-SYNTAX
endmodule

module VERIFICATION
  imports SCHEMA-INDEX-SPEC-SYNTAX
  imports SCHEMA-INDEX
  imports SET
  imports K-EQUAL

  // Map-extensionality-style helper is not needed (no maps); the only VCs are
  // finite set-cardinality facts, dischargeable by Z3 once cnames is unfolded.
endmodule

module SCHEMA-INDEX-SPEC
  imports VERIFICATION

  // (FILTER) — loop circularity for the _constraint_names scan.
  // Generalized over the remaining list CS and the accumulator R: scanning the
  // rest of the constraints adds exactly cnames(CS,...) to the result set.
  claim <k> filter => checkDelete ... </k>
        <cons> CS:Cons => .Cons </cons>
        <cols> COLS </cols> <kw> KW </kw> <excl> EXCL </excl>
        <result> R:Set => R cnames(CS, COLS, KW, EXCL) </result>
    [all-path]

  // ---------------------------------------------------------------------------
  // The Django scenario from the bug report: a 2-field model carrying BOTH a
  // unique_together and an index_together over the SAME columns (a, b).
  //   c_uniq = con("t_uniq", (a,b), unique=true,  index=IU)
  //   c_idx  = con("t_idx",  (a,b), unique=false, index=true)
  // IU is the backend's report of "is the unique constraint also an index?":
  //   MySQL / SQLite : IU = true   (unique constraint is backed by an index)
  //   PostgreSQL     : IU = false  (constraint and index share a name; index=false kept)
  // Neither name is in EXCL (they come from *_together, not Meta.indexes/constraints).
  // ---------------------------------------------------------------------------

  // (DEL-IDX) — V1 index deletion succeeds and removes exactly c_idx, on ANY
  // backend (IU symbolic). This is the fixed behavior.
  claim <k> filter ~> checkDelete => deleted(SetItem("t_idx")) ... </k>
        <cons> con("t_uniq", a , b , true , IU:Bool)
             ; con("t_idx",  a , b , false, true)
            => .Cons </cons>
        <cols> a , b </cols>
        <kw> idxFilter </kw>
        <excl> .Set => ?_:Set </excl>
        <result> .Set => ?_:Set </result>
    [all-path]

  // (DEL-IDX-V0) — CONTRAST: the pre-fix filter {'index':True} on a backend
  // where the unique constraint is also reported as an index (IU=true, i.e.
  // MySQL/SQLite) collects BOTH names, so size==2 and _delete_composed_index
  // raises ValueError. This claim reproduces the reported crash.
  claim <k> filter ~> checkDelete => valueError(2) ... </k>
        <cons> con("t_uniq", a , b , true , true)
             ; con("t_idx",  a , b , false, true)
            => .Cons </cons>
        <cols> a , b </cols>
        <kw> idxFilterV0 </kw>
        <excl> .Set => ?_:Set </excl>
        <result> .Set => ?_:Set </result>
    [all-path]

  // (DEL-UNIQ) — the symmetric direction is already safe WITHOUT any change:
  // {'unique':True} matches only c_uniq, because the index_together index is
  // non-unique. Holds for any backend (IU symbolic). Justifies leaving
  // alter_unique_together untouched.
  claim <k> filter ~> checkDelete => deleted(SetItem("t_uniq")) ... </k>
        <cons> con("t_uniq", a , b , true , IU:Bool)
             ; con("t_idx",  a , b , false, true)
            => .Cons </cons>
        <cols> a , b </cols>
        <kw> uniqFilter </kw>
        <excl> .Set => ?_:Set </excl>
        <result> .Set => ?_:Set </result>
    [all-path]

  // (DEL-IDX-DRIFT) — latent-hazard claim: if the _idx index is already gone
  // (DB drift) and only c_uniq remains, then on IU=true backends the PRE-FIX
  // filter would have size==1 and SILENTLY delete the unique constraint with a
  // DROP INDEX. V1's {'unique':False} instead yields size==0 -> ValueError, a
  // safe loud failure rather than a wrong deletion. (Shown for the V1 filter.)
  claim <k> filter ~> checkDelete => valueError(0) ... </k>
        <cons> con("t_uniq", a , b , true , true) => .Cons </cons>
        <cols> a , b </cols>
        <kw> idxFilter </kw>
        <excl> .Set => ?_:Set </excl>
        <result> .Set => ?_:Set </result>
    [all-path]
endmodule
