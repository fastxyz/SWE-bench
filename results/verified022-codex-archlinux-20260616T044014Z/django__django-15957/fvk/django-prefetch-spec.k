requires "mini-django-prefetch.k"

module DJANGO-PREFETCH-SPEC
  imports MINI-DJANGO-PREFETCH
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - SPEC I1/I6, PO1: unsliced querysets are filtered directly; sliced
  //   querysets must be rewritten before filter is applied.
  claim filterPrefetch(query(false, L, H, O, SUPPORTS), relPred, fkKey)
    => ok(query(false, L, H, O, SUPPORTS), relPred, O)

  // SPEC-PROVENANCE:
  // - SPEC I2/I3/I4, PO2: sliced queryset [L:] becomes per-partition
  //   row_number > L after clearing limits.
  claim filterPrefetch(query(true, L, none, O, true), relPred, fkKey)
    => ok(
         query(false, 0, none, normalizeOrder(O), true),
         relPred andP rankGt(L),
         normalizeOrder(O)
       )

  // SPEC-PROVENANCE:
  // - SPEC I2/I3/I4, PO2: sliced queryset [L:H] becomes row_number > L and
  //   row_number <= H after clearing limits.
  claim filterPrefetch(query(true, L, some(H), O, true), relPred, fkKey)
    => ok(
         query(false, 0, none, normalizeOrder(O), true),
         relPred andP rankGt(L) andP rankLte(H),
         normalizeOrder(O)
       )

  // SPEC-PROVENANCE:
  // - SPEC I5, FINDINGS F2, PO4: unordered sliced querysets use primary-key
  //   fallback ordering to make ROW_NUMBER backend-valid.
  claim filterPrefetch(query(true, L, some(H), emptyOrder, true), relPred, fkKey)
    => ok(
         query(false, 0, none, pkOrder, true),
         relPred andP rankGt(L) andP rankLte(H),
         pkOrder
       )

  // SPEC-PROVENANCE:
  // - SPEC I8, PO5: no window support is an explicit capability failure.
  claim filterPrefetch(query(true, L, H, O, false), relPred, fkKey)
    => errorNotSupported

  // SPEC-PROVENANCE:
  // - PO6: manager cache paths use the same helper contract with corePred.
  claim filterPrefetch(query(true, L, some(H), O, true), corePred, m2mKey)
    => ok(
         query(false, 0, none, normalizeOrder(O), true),
         corePred andP rankGt(L) andP rankLte(H),
         normalizeOrder(O)
       )
endmodule
