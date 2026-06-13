// json_path-spec.k — reachability claims for the JSONField has_key path builders.
// Proven against fvk/json_path.k. "constructed, not machine-checked."
//
// Run-commands (MVP does NOT execute them):
//   kompile json_path.k --backend haskell
//   kast    --backend haskell json_path-spec.k
//   kprove  json_path-spec.k          // expected: #Top (all claims proved)

requires "json_path.k"

module JSON-PATH-SPEC-SYNTAX
  imports JSON-PATH
endmodule

module VERIFICATION
  imports JSON-PATH-SPEC-SYNTAX
  imports JSON-PATH
  imports K-EQUAL

  // -------- arithmetic/string [simplification] lemmas the VCs need -----------

  // L1 (associativity of +String) — the fold may re-associate concatenations.
  rule (A:String +String B:String) +String C:String
    => A +String (B +String C)                                     [simplification]

  // L2 (left identity) — cjp(.List) = "" contributes nothing.
  rule "" +String A:String => A                                    [simplification]
  rule A:String +String "" => A                                    [simplification]
endmodule

module JSON-PATH-SPEC
  imports VERIFICATION

  // ====================================================================
  // (FINALKEY)  HasKeyLookup.compile_json_path_final_key(K)
  //   Contract: for every key string K, the final-key segment is the OBJECT
  //   member ".":json.dumps(K) — and it is an object token for ALL K, including
  //   numeric K (parsesAsInt(K) = true). This is the bug fix, stated formally.
  //   Precondition: K:String (see Finding F-int / F-none for non-string K).
  // ====================================================================
  claim <k> compile_json_path_final_key(K:String) => RES:String ... </k>
    ensures (RES ==String segObject(K))
    andBool (isObjectToken(RES) ==Bool true)
    [one-path]

  // ====================================================================
  // (SEG-VS-OBJECT)  The fix, contrasted with the pre-fix behaviour.
  //   For a NUMERIC key (parsesAsInt(K)), the OLD final-key form seg(K) is an
  //   array token "[K]" (the bug: $[1111]); the NEW form segObject(K) is the
  //   object token "."+dumps(K) ($."1111"). They differ exactly on numeric keys.
  // ====================================================================
  claim <k> segDiff(K:String) => true ... </k>
    requires parsesAsInt(K)
    ensures notBool (seg(K) ==String segObject(K))
    [one-path]

  // ====================================================================
  // (HOMO)  compile_json_path is a concatenation homomorphism on the key list.
  //   cjp(A ++ B) = cjp(A) +String cjp(B).  This is the loop invariant of the
  //   `for key_transform in key_transforms` loop in compile_json_path, proved by
  //   list induction (the circularity). It underpins PRESERVE below.
  // ====================================================================
  claim <k> cjp(A:List ++List B:List) => R:String ... </k>
    ensures R ==String (cjp(A) +String cjp(B))
    [one-path]

  // ====================================================================
  // (PRESERVE)  HasKeyOrArrayIndex reproduces the ORIGINAL whole-list path.
  //   For navigation NAV and final key FINAL,
  //     buildPathArr(LJP, NAV, FINAL) == LJP +String cjp(NAV ++ [FINAL]).
  //   i.e. splitting nav/final and re-joining yields exactly the pre-fix
  //   compile_json_path(NAV ++ [FINAL], include_root=False). Zero regression for
  //   the isnull / exact-null callers that use HasKeyOrArrayIndex.
  // ====================================================================
  claim <k> buildPathArr(LJP:String, NAV:List, FINAL:String) => R:String ... </k>
    ensures R ==String (LJP +String cjp(NAV ++List ListItem(FINAL)))
    [one-path]

  // ====================================================================
  // (ASSQL-OBJECT)  One iteration of HasKeyLookup.as_sql's rhs loop, has_key
  //   family: the produced rhs path is lhs_json_path ++ navigation ++ OBJECT
  //   final key; the final key is an object token for ALL FINAL (incl. numeric).
  // ====================================================================
  claim <k> buildPathObj(LJP:String, NAV:List, FINAL:String) => R:String ... </k>
    ensures (R ==String (LJP +String cjp(NAV) +String segObject(FINAL)))
    andBool (isObjectToken(segObject(FINAL)) ==Bool true)
    [one-path]

endmodule
