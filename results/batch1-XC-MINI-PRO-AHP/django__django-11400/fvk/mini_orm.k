// mini_orm.k — a minimal ("mini-X") K fragment modeling the ORDERING-relevant
// state of a Django QuerySet, exactly as much as the patched methods touch.
//
// FAITHFULNESS (the trusted base — each rule mirrors a cited source location):
//   * Query.add_ordering / Query.clear_ordering
//       repo/django/db/models/sql/query.py:1858-1891
//   * SQLCompiler.get_order_by  (the branch ladder)
//       repo/django/db/models/sql/compiler.py:262-273
//   * QuerySet.order_by / .all / .complex_filter
//       repo/django/db/models/query.py:1073-1080, 881, 916-931
//   * Manager.all / Model._default_manager
//       repo/django/db/models/manager.py:146
//   * Field.get_choices / ForeignObjectRel.get_choices (the PATCHED methods)
//       repo/django/db/models/fields/__init__.py:809-833
//       repo/django/db/models/fields/reverse_related.py:117-130
//
// The ONLY semantic distinction the fix turns on is empty-vs-nonempty ordering
// (the `if ordering:` guard and the compiler ladder), so we abstract concrete
// field-name tuples to that single bit: `.Ord` is the empty tuple (); any other
// `Ord` value is a non-empty tuple. Nothing else about a queryset is modeled.

module MINI-ORM-SYNTAX
  imports BOOL-SYNTAX

  // An "ordering" is an opaque tuple of field names. We keep one concrete
  // inhabitant, `.Ord` = the empty tuple (); every other Ord is symbolic and
  // its non-emptiness is carried as a `requires isTruthy(_)` side condition.
  syntax Ord ::= ".Ord"                       // the empty ordering ()   [Python-falsy]

  // A queryset value carries EXACTLY the three fields get_order_by reads:
  //   qs(OB, DO, META): explicit .order_by OB, .default_ordering DO,
  //                     and the related model's Meta.ordering META.
  syntax QS ::= "qs" "(" Ord "," Bool "," Ord ")"

  // The functional fragment the patched code uses (straight-line; no counter loop —
  // the list comprehension is a pure order-preserving map, see SPEC.md note L1).
  syntax Bool ::= "isTruthy" "(" Ord ")"                      [function]
  syntax QS  ::= "defaultManager" "(" Ord ")"                 [function]  // Model._default_manager
               | "allQ" "(" QS ")"                            [function]  // QuerySet.all()
               | "complexFilter" "(" QS ")"                   [function]  // .complex_filter(limit_choices_to)
               | "orderByQ" "(" QS "," Ord ")"                [function]  // .order_by(*ordering)
  syntax Ord ::= "effOrdering" "(" QS ")"                     [function]  // ordering the SQL compiler emits

  // The two patched get_choices cores (forward Field vs reverse ForeignObjectRel)
  // and the filter-layer helpers, as straight-line functions over the algebra above.
  syntax QS  ::= "getChoicesFwd" "(" Ord "," Ord ")"          [function]  // Field.get_choices  (META, ORD)
               | "getChoicesRev" "(" Ord "," Ord ")"          [function]  // ForeignObjectRel.get_choices (META, ORD)
  syntax Ord ::= "choicesOrdering" "(" Ord "," Ord ")"        [function]  // effOrdering of the result
               | "fieldAdminOrdering" "(" Bool "," Ord ")"    [function]  // RelatedFieldListFilter.field_admin_ordering
               | "fieldChoicesOrdering" "(" Bool "," Ord "," Ord ")" [function] // resulting ordering of field_choices

  // --- The PRE-FIX cores, kept so the proof can exhibit the bug as a counterexample.
  syntax QS  ::= "getChoicesFwdOLD" "(" Ord "," Ord ")"       [function]
  syntax Ord ::= "choicesOrderingOLD" "(" Ord "," Ord ")"     [function]
endmodule

module MINI-ORM
  imports MINI-ORM-SYNTAX
  imports BOOL

  // ---- Python truthiness of an ordering tuple: () is falsy, any non-empty tuple truthy.
  //   (`isTruthy(ORD)` for a symbolic non-empty ORD is supplied as a claim `requires`.)
  rule isTruthy(.Ord) => false

  // ---- Model._default_manager.get_queryset(): a fresh QuerySet.
  //   default_ordering = True, explicit order_by = ();  carries the model's Meta.ordering.
  //   (sql/query.py:168 sets self.default_ordering = True on a new Query.)
  rule defaultManager(META) => qs(.Ord, true, META)

  // ---- QuerySet.all()  ==  get_queryset()  : ordering state preserved (manager.py:146).
  rule allQ(qs(OB, DO, META)) => qs(OB, DO, META)

  // ---- QuerySet.complex_filter(...) : add_q / _filter_or_exclude only — never touches
  //   order_by or default_ordering (query.py:916-931). Ordering state preserved.
  rule complexFilter(qs(OB, DO, META)) => qs(OB, DO, META)

  // ---- QuerySet.order_by(*ORD)  ==  clear_ordering(force_empty=False); add_ordering(*ORD)
  //   clear_ordering(False): order_by := () ; default_ordering UNCHANGED   (query.py:1883-1891)
  //   add_ordering(*ORD):                                                   (query.py:1858-1881)
  //        ORD non-empty -> order_by := ORD          (default_ordering unchanged)
  //        ORD empty ()  -> default_ordering := False (order_by stays ())   <-- the trap
  rule orderByQ(qs(_, DO, META), ORD) => qs(ORD, DO, META)  requires isTruthy(ORD)
  rule orderByQ(qs(_,  _, META), .Ord) => qs(.Ord, false, META)

  // ---- SQLCompiler.get_order_by ladder (extra_order_by is always () here) — compiler.py:262-273
  //   not default_ordering            -> order_by                 (branch 2)
  //   elif order_by (non-empty)       -> order_by                 (branch 3)
  //   elif Meta.ordering (non-empty)  -> Meta.ordering            (branch 4)
  //   else                            -> ()                       (branch 5)
  rule effOrdering(qs(OB,  false, _))     => OB                    requires isTruthy(OB)   // br2, non-empty
  rule effOrdering(qs(.Ord, false, _))    => .Ord                                          // br2, empty  -> NO ordering
  rule effOrdering(qs(OB,  true,  _))     => OB                    requires isTruthy(OB)   // br3
  rule effOrdering(qs(.Ord, true,  META)) => META                                          // br4/br5

  // ======================= THE PATCHED CODE, as functions =======================

  // Field.get_choices(..., ordering=ORD)   [fields/__init__.py:809-833, POST-FIX]:
  //     qs = rel_model._default_manager.complex_filter(limit_choices_to)
  //     if ordering: qs = qs.order_by(*ordering)
  //     return [...for x in qs]            # comprehension preserves qs order (note L1)
  rule getChoicesFwd(META, ORD) => orderByQ(complexFilter(defaultManager(META)), ORD)  requires isTruthy(ORD)
  rule getChoicesFwd(META, .Ord) =>          complexFilter(defaultManager(META))                  // if-false: skip order_by

  // ForeignObjectRel.get_choices(..., ordering=ORD) [reverse_related.py:117-130, POST-FIX]:
  //     qs = self.related_model._default_manager.all()
  //     if ordering: qs = qs.order_by(*ordering)
  rule getChoicesRev(META, ORD) => orderByQ(allQ(defaultManager(META)), ORD)            requires isTruthy(ORD)
  rule getChoicesRev(META, .Ord) =>          allQ(defaultManager(META))

  // The observable: the order in which the choices come out == effOrdering(final qs).
  rule choicesOrdering(META, ORD) => effOrdering(getChoicesFwd(META, ORD))

  // RelatedFieldListFilter.field_admin_ordering(field, request, model_admin)
  //   [filters.py:196-203]:  related_admin not None -> get_ordering() ;  else ()
  //   (AO already encodes get_ordering() == self.ordering or () : AO is .Ord or non-empty.)
  rule fieldAdminOrdering(true,  AO) => AO
  rule fieldAdminOrdering(false, _)  => .Ord

  // field_choices = get_choices(ordering = field_admin_ordering(...))   [filters.py:205-207 / 425-429]
  rule fieldChoicesOrdering(HASADM, AO, META) => choicesOrdering(META, fieldAdminOrdering(HASADM, AO))

  // ======================= THE PRE-FIX CODE (for the counterexample) =======================
  // OLD Field.get_choices: `....order_by(*ordering)` UNCONDITIONALLY.
  rule getChoicesFwdOLD(META, ORD) => orderByQ(complexFilter(defaultManager(META)), ORD)
  rule choicesOrderingOLD(META, ORD) => effOrdering(getChoicesFwdOLD(META, ORD))
endmodule
