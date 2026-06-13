// schema_index.k — mini fragment modeling the constraint-resolution code in
// django/db/backends/base/schema.py used by:
//   * _constraint_names()      (the filtering for-loop)
//   * _delete_composed_index() (the `len(constraint_names) != 1` guard)
//   * alter_index_together() / alter_unique_together() (which pick the kwargs)
//
// It covers ONLY what those functions touch: a table's introspected constraint
// descriptors (name, ordered column tuple, unique?, index?), a (columns + kwargs
// + excluded-names) filter, a result accumulator, and the |result| == 1 guard.
//
// MVP / honesty note: this is the "mini-X" stopgap semantics. It is CONSTRUCTED,
// NOT MACHINE-CHECKED — no K toolchain (kompile/kprove) runs in this environment.
// The arithmetic here is just finite set cardinality, so the proof is light; the
// real content is the domain reasoning recorded in ../fvk/PROOF.md.

module SCHEMA-INDEX-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  // A constraint descriptor as returned by DatabaseIntrospection.get_constraints():
  //   con(Name, Cols, Unique, Index)
  // (primary_key / check / foreign_key are dropped from the fragment because the
  //  two call sites only ever pin 'unique' and 'index'; the primary-key edge is
  //  recorded as Finding F5 instead of modeled here.)
  syntax Con  ::= "con" "(" String "," Cols "," Bool "," Bool ")"
  syntax Cons ::= List{Con, ";"}            // the table's constraint list (introspection order)
  syntax Cols ::= List{String, ","}         // an ordered column tuple

  // The two concrete kwargs dicts the callers pass, plus the pre-fix variant:
  syntax KW ::= "idxFilter"      // {'index': True, 'unique': False}  -- alter_index_together (V1)
              | "idxFilterV0"    // {'index': True}                   -- alter_index_together (V0, pre-fix)
              | "uniqFilter"     // {'unique': True}                  -- alter_unique_together

  syntax Stmt ::= "filter" | "checkDelete"
  syntax KResult ::= Int | Bool
endmodule

module SCHEMA-INDEX
  imports SCHEMA-INDEX-SYNTAX
  imports INT
  imports BOOL
  imports SET

  configuration
    <k>      $PGM:Stmt  </k>
    <cons>   $CONS:Cons </cons>    // remaining constraints to scan
    <cols>   $COLS:Cols </cols>    // target column tuple
    <kw>     $KW:KW      </kw>      // active filter (one of the three above)
    <excl>   $EXCL:Set   </excl>    // excluded names = Meta.constraints | Meta.indexes
    <result> .Set        </result>  // accumulated matching constraint names

  // ---- matches(C, Cols, KW, Excl) — the per-constraint predicate ----------
  // Mirrors the body of _constraint_names: exact column-tuple match, every
  // pinned kw flag equal, and the name not excluded.
  syntax Bool ::= matches(Con, Cols, KW, Set) [function, total]
  rule matches(con(NAME, CC, U, IX), COLS, KW, EXCL)
    => (CC ==K COLS) andBool kwMatch(KW, U, IX) andBool notBool (NAME in EXCL)

  // kwMatch(KW, unique, index): the kwargs comparison in _constraint_names.
  syntax Bool ::= kwMatch(KW, Bool, Bool) [function, total]
  rule kwMatch(idxFilter,   U, IX) => IX andBool (U ==Bool false)   // {'index':True,'unique':False}
  rule kwMatch(idxFilterV0, _U, IX) => IX                            // {'index':True}
  rule kwMatch(uniqFilter,  U, _IX) => U                             // {'unique':True}

  // ---- cnames(...) — spec-only abstraction: the set of matching names ------
  // (the value _constraint_names returns, as a Set; used by the loop circularity)
  syntax Set ::= cnames(Cons, Cols, KW, Set) [function, total]
  rule cnames(.Cons, _, _, _) => .Set
  rule cnames(C ; REST, COLS, KW, EXCL)
    => SetItem(nameOf(C)) cnames(REST, COLS, KW, EXCL)
    requires matches(C, COLS, KW, EXCL)
  rule cnames(C ; REST, COLS, KW, EXCL)
    => cnames(REST, COLS, KW, EXCL)
    requires notBool matches(C, COLS, KW, EXCL)
  syntax String ::= nameOf(Con) [function, total]
  rule nameOf(con(N, _, _, _)) => N

  // ---- the scan loop (the for-loop in _constraint_names) ------------------
  rule <k> filter => checkDelete ... </k>
       <cons> .Cons </cons>
  rule <k> filter ... </k>
       <cons> C ; REST => REST </cons>
       <cols> COLS </cols> <kw> KW </kw> <excl> EXCL </excl>
       <result> R => R SetItem(nameOf(C)) </result>
    requires matches(C, COLS, KW, EXCL)
  rule <k> filter ... </k>
       <cons> C ; REST => REST </cons>
       <cols> COLS </cols> <kw> KW </kw> <excl> EXCL </excl>
       <result> R </result>
    requires notBool matches(C, COLS, KW, EXCL)

  // ---- the |constraint_names| == 1 guard (_delete_composed_index) ---------
  syntax KItem ::= "deleted" "(" Set ")" | "valueError" "(" Int ")"
  rule <k> checkDelete => deleted(R)         ... </k> <result> R </result>
    requires size(R) ==Int 1
  rule <k> checkDelete => valueError(size(R)) ... </k> <result> R </result>
    requires size(R) =/=Int 1
endmodule
