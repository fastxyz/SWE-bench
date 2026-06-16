requires "mini-migration-optimizer.k"

module MIGRATION-OPTIMIZER-SPEC
  imports MINI-MIGRATION-OPTIMIZER

  // SPEC-PROVENANCE:
  // - from_prompt: "Reduce Add/RemoveIndex migration operations." =>
  //   matching add/remove on the same model and exact index name reduces away.
  claim <k> reduce(addIndex(M, N, P), removeIndex(M, N))
        => replace(.OpList) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Reduce Add/RemoveIndex migration operations." =>
  //   a rename of the just-added index composes with the add, allowing a later
  //   remove of the final name to cancel.
  claim <k> reduce(addIndex(M, Old, P), renameIndex(M, New, someName(Old)))
        => replace(addIndex(M, New, P), .OpList) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: ModelOperation.reduce() can pass through operations that do
  //   not reference its model; IndexOperation must expose the same model frame.
  claim <k> reduce(addIndex(M, N, P), otherOp(false))
        => cross(true) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: exact index-name matching in ProjectState.remove_index().
  claim <k> reduce(addIndex(M, N1, P), removeIndex(M, N2))
        => cross(false) </k>
    requires N1 =/=String N2
    [all-path]
endmodule
