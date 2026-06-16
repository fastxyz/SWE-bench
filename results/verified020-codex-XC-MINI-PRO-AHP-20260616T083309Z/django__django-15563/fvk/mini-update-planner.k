// Constructed FVK artifact, not machine-checked.
// Mini semantics for the update-planning fragment only. It models the
// observable that matters for django__django-15563: the identifier list used by
// each update target.

module MINI-UPDATE-PLANNER-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX
  imports LIST-SYNTAX
  imports ID-SYNTAX

  syntax Model ::= Id
  syntax Ids ::= List
  syntax ModelIds ::= Map
  syntax Filters ::= Map

  syntax Plan ::= preSqlSetup(Ids, ModelIds)
                | getRelatedUpdates(ModelIds)
                | bugDiscriminator(Ids, Ids)
                | done(Ids, ModelIds, Filters)
                | relatedDone(Filters)
                | bugDone(Filters)

  syntax KResult ::= done(Ids, ModelIds, Filters)
                   | relatedDone(Filters)
                   | bugDone(Filters)
endmodule

module MINI-UPDATE-PLANNER
  imports MINI-UPDATE-PLANNER-SYNTAX
  imports MAP
  imports LIST

  configuration <k> $PGM:Plan </k>

  // preSqlSetup(PKIDS, RIDS) models selecting the queryset primary keys and the
  // per-related-model parent-link identifiers from the same stable pre-update
  // row snapshot. The main query receives PKIDS; related filters are produced by
  // getRelatedUpdates(RIDS).
  rule <k> preSqlSetup(PKIDS:Ids, RIDS:ModelIds)
        => done(PKIDS, RIDS, makeFilters(RIDS)) ... </k>

  // getRelatedUpdates must filter each target model by the identifier list
  // stored under that model key.
  rule <k> getRelatedUpdates(RIDS:ModelIds)
        => relatedDone(makeFilters(RIDS)) ... </k>

  // Discriminator for the reported bug. The old behavior used ChildPKS for the
  // OtherBase update. The intended behavior uses OtherBase parent-link IDs.
  rule <k> bugDiscriminator(ChildPKS:Ids, OtherBaseLinkIds:Ids)
        => bugDone(otherbase |-> OtherBaseLinkIds) ... </k>

  syntax Filters ::= makeFilters(ModelIds) [function]
  rule makeFilters(.Map) => .Map
  rule makeFilters((M:Model |-> IDS:Ids) RIDS:ModelIds)
    => (M |-> IDS) makeFilters(RIDS)
endmodule
