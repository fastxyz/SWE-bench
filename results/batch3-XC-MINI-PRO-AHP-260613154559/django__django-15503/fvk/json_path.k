// json_path.k — mini-Python (mini-X) fragment for the JSONField has_key path
// builders. Covers ONLY the constructs actually used by the V1/V2 fix in
// django/db/models/fields/json.py:
//   * compile_json_path(key_transforms, include_root)
//   * HasKeyLookup.compile_json_path_final_key(key_transform)        (V2)
//   * HasKeyOrArrayIndex.compile_json_path_final_key(key_transform)
//   * the `for key in rhs` loop inside HasKeyLookup.as_sql
//
// MVP stopgap (per fvk_materials/commands/formalize.md §3): this is a deliberately
// small fragment, NOT a real Python-in-K. Keys are K Strings, key lists are K
// Lists, and the two opaque library calls are modelled as abstract symbols:
//   * parsesAsInt(S)  models  `try: int(S) except ValueError`  (Python str->int)
//   * dumps(S)        models  `json.dumps(S)` for a STRING S (a JSON-quoted token)
// "constructed, not machine-checked."

requires "domains.md"   // STRING, LIST, BOOL, INT, K-EQUAL builtins

module JSON-PATH
  imports STRING
  imports BOOL
  imports LIST
  imports INT
  imports K-EQUAL

  // -------- abstract models of the two opaque Python library calls ----------

  // parsesAsInt(S) is true iff Python's int(S) returns without raising
  // ValueError, e.g. "1111" -> true, "foo" -> false. Total Boolean predicate;
  // its exact extension is irrelevant to the proof — only the case split matters.
  syntax Bool ::= parsesAsInt(String) [function, total]

  // dumps(S) models json.dumps(S) for a STRING S: the JSON-encoded token, which
  // for a string is ALWAYS a double-quoted, escaped string literal. The proof
  // only needs the single structural fact that the result is a quoted token and
  // never an array-bracket token — captured by isObjectToken below.
  syntax String ::= dumps(String) [function, total]

  // isObjectToken(T) holds iff T is rendered as a JSON object-member token: it
  // begins with the member separator/quote and is not an array-index token
  // ("[" ... "]"). Used to state the bug-fix postcondition precisely.
  syntax Bool ::= isObjectToken(String) [function, total]
  rule isObjectToken(T) => (findString(T, ".\"", 0) ==Int 0)

  // dumps(S) of any string is a quoted token, so ".":dumps(S) is an object token.
  rule isObjectToken("." +String dumps(_)) => true                 [simplification]
  // an array-index token is NEVER an object token (distinct first character).
  rule isObjectToken("[" +String _)        => false                [simplification]

  // -------- segment builders (the body of compile_json_path's loop) ----------

  // seg(K): the per-key segment exactly as compile_json_path emits it —
  //   try: int(K)            -> "[K]"  (array index)
  //   except ValueError      -> "." + json.dumps(K)  (object member)
  syntax String ::= seg(String) [function, total]
  rule seg(K) => "[" +String K +String "]"   requires parsesAsInt(K)
  rule seg(K) => "." +String dumps(K)         requires notBool parsesAsInt(K)

  // segObject(K): the OBJECT-ONLY segment. This is what
  // HasKeyLookup.compile_json_path_final_key emits — note: NO parsesAsInt branch,
  // so a numeric key is still an object member. (V2 additionally coerces K with
  // str(); modelled here at the String level where str(K)==K.)
  syntax String ::= segObject(String) [function, total]
  rule segObject(K) => "." +String dumps(K)

  // -------- compile_json_path as a fold over the key list --------------------
  // cjp(KS) == compile_json_path(KS, include_root=False): concat of seg over KS.
  // The Python `for key_transform in key_transforms: path.append(...)` loop is
  // modelled as this left fold; its loop invariant is the homomorphism lemma in
  // json_path-spec.k (HOMO).
  syntax String ::= cjp(List) [function, total]
  rule cjp(.List)                       => ""
  rule cjp(ListItem(K:String) REST:List) => seg(K) +String cjp(REST)

  // root("$") prefix is added when include_root=True; the has_key paths take the
  // root from the LHS (lhs_json_path) and call cjp with include_root=False, so we
  // only ever need the False form here.

  // -------- the rhs key loop of HasKeyLookup.as_sql --------------------------
  // buildPathObj / buildPathArr model one loop iteration's rhs_json_path for the
  // has_key family vs. the HasKeyOrArrayIndex internal helper respectively, given
  // the already-computed lhs_json_path prefix LJP and the per-key transforms
  //   NAV ++ ListItem(FINAL)  (navigation segments + final key).
  syntax String ::= buildPathObj(String, List, String) [function, total]   // has_key family
                  | buildPathArr(String, List, String) [function, total]   // HasKeyOrArrayIndex
  rule buildPathObj(LJP, NAV, FINAL) => LJP +String cjp(NAV) +String segObject(FINAL)
  rule buildPathArr(LJP, NAV, FINAL) => LJP +String cjp(NAV) +String seg(FINAL)

endmodule
