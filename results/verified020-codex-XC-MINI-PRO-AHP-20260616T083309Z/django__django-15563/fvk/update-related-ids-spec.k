// Constructed FVK artifact, not machine-checked.
requires "mini-update-planner.k"

module UPDATE-RELATED-IDS-SPEC
  imports MINI-UPDATE-PLANNER
  imports MAP
  imports LIST

  // SPEC-PROVENANCE:
  // - E2/E4/E5: related ancestor updates must use parent-link identifiers.
  // - E3/E6: related_ids is keyed by target model and consumed as related_ids[model].
  claim
    <k> preSqlSetup(PKIDS:Ids, RIDS:ModelIds)
      => done(PKIDS, RIDS, makeFilters(RIDS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: get_related_updates() filters each UpdateQuery(model) with related_ids[model].
  claim
    <k> getRelatedUpdates(RIDS:ModelIds)
      => relatedDone(makeFilters(RIDS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: if child/base primary keys differ from OtherBase parent-link IDs, the
  //   OtherBase filter must use the parent-link IDs, not child/base primary keys.
  claim
    <k> bugDiscriminator(ListItem(1) ListItem(2), ListItem(3) ListItem(4))
      => bugDone(otherbase |-> (ListItem(3) ListItem(4))) </k>
    [all-path]
endmodule
