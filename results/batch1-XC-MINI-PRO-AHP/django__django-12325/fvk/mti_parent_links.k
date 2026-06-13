// mti_parent_links.k
// ---------------------------------------------------------------------------
// A "mini-X" K fragment semantics for the parent-link COLLECTION loop in
// django/db/models/base.py (ModelBase.__new__), as patched by the V1 fix.
//
// Source code being modelled (repo/django/db/models/base.py:194-219):
//
//     parent_links = {}
//     for base in reversed([new_class] + parents):
//         if not hasattr(base, '_meta'):           continue
//         if base != new_class and not base._meta.abstract: continue
//         for field in base._meta.local_fields:
//             if isinstance(field, OneToOneField):
//                 related = resolve_relation(new_class, field.remote_field.model)
//                 related_key = make_model_tuple(related)
//                 existing = parent_links.get(related_key)
//                 if (existing is not None and
//                         existing.remote_field.parent_link and
//                         not field.remote_field.parent_link):
//                     continue
//                 parent_links[related_key] = field
//
// ABSTRACTION (faithful "reduced in-domain body", per formalize.md step 5):
//   * The two nested loops + the three `continue` filters (`hasattr`,
//     `base != new_class and not abstract`, `isinstance(.., OneToOneField)`)
//     only DECIDE WHICH fields, in WHAT ORDER, reach the body. We model that
//     post-filter, flattened, ordered sequence directly as a list `VS:Fields`.
//     The filters become the *definition of VS* (a precondition), exactly the
//     "model the reduced in-domain body, turn the guards into Findings"
//     guidance. See fvk/FINDINGS.md F-5/F-6.
//   * Each surviving OneToOneField is abstracted to the only three attributes
//     the body inspects, plus an identity:
//         field(K, PL, ID)
//       K  : Int  = make_model_tuple(resolve_relation(.., field.remote_field.model))
//                   i.e. the *parent model key* the OneToOneField points at.
//       PL : Int  = 1 if field.remote_field.parent_link else 0
//       ID : Int  = a unique field identity (so "result IS one of the
//                   candidates" / I1 is expressible).
//   * `parent_links` is the <plinks> cell: a Map from K (Int) to the chosen
//     Field. `parent_links.get(K)` is `M[K]` guarded by `K in_keys(M)`.
//
// The `skip(...)` helper below is the exact V1 guard, written so that the
// short-circuit of Python's `and` (existing-not-None gates the attribute
// reads) is preserved: plOf(M[K]) is only ever evaluated when K in_keys(M).
// ---------------------------------------------------------------------------

module MTI-PARENT-LINKS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // A modelled OneToOneField candidate: field(parentKey, parentLinkFlag, id).
  syntax Field  ::= field(Int, Int, Int)

  // The flattened, post-filter, ordered visit list (".Fields" = empty).
  syntax Fields ::= List{Field, ";"} [klabel(fields)]

  // The loop, as a fold over the visit list.
  syntax KItem  ::= select(Fields)
endmodule

module MTI-PARENT-LINKS
  imports MTI-PARENT-LINKS-SYNTAX
  imports INT
  imports BOOL
  imports MAP

  configuration
    <k>       $PGM:KItem </k>
    <plinks>  .Map       </plinks>     // parent_links : Int(key) |-> Field

  // ---- projections on a Field --------------------------------------------
  syntax Int ::= plOf(Field)  [function, total]
               | keyOf(Field)  [function, total]
               | idOf(Field)   [function, total]
  rule plOf(field(_, PL, _))  => PL
  rule keyOf(field(K, _, _))  => K
  rule idOf(field(_, _, ID))  => ID

  // ---- the V1 guard: "skip iff existing is a parent link and new is not" ---
  // Total + short-circuiting: M[K] is read only when K in_keys(M).
  syntax Bool ::= skip(Map, Int, Int) [function, total]
  rule skip(M, K, PL) => true
    requires (K in_keys(M)) andBool (plOf({M[K]}:>Field) ==Int 1) andBool (PL ==Int 0)
  rule skip(M, K, PL) => false
    requires notBool K in_keys(M)
  rule skip(M, K, PL) => false
    requires (K in_keys(M))
     andBool notBool ((plOf({M[K]}:>Field) ==Int 1) andBool (PL ==Int 0))

  // ---- the per-element update (the if/continue/assign body) ---------------
  syntax Map ::= updateSel(Map, Field) [function, total]
  rule updateSel(M, field(K, PL, ID)) => M
    requires skip(M, K, PL)                                   // continue
  rule updateSel(M, field(K, PL, ID)) => M[K <- field(K, PL, ID)]
    requires notBool skip(M, K, PL)                           // parent_links[K] = field

  // ---- the loop, small-step over the visit list ---------------------------
  rule <k> select(.Fields) => .K ... </k>
  rule <k> select(F:Field ; Rest:Fields) => select(Rest) ... </k>
       <plinks> M:Map => updateSel(M, F) </plinks>
endmodule
