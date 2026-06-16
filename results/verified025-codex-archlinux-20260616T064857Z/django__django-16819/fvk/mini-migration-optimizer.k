module MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL
  imports STRING

  syntax MaybeName ::= noName | someName(String)
  syntax Payload ::= payload(String)
  syntax Op ::= addIndex(String, String, Payload)
              | removeIndex(String, String)
              | renameIndex(String, String, MaybeName)
              | otherOp(Bool)
  syntax OpList ::= ".OpList" | Op "," OpList [right]
  syntax ReduceResult ::= replace(OpList) | cross(Bool)
endmodule

module MINI-MIGRATION-OPTIMIZER
  imports MINI-MIGRATION-OPTIMIZER-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  // Model names are represented after Django's model_name_lower normalization.
  syntax Bool ::= sameModel(String, String) [function]
  rule sameModel(M, M) => true
  rule sameModel(_, _) => false [owise]

  // Index names are intentionally exact. ProjectState.remove_index() compares
  // obj.name to the requested name without lower-casing.
  syntax Bool ::= sameName(String, String) [function]
  rule sameName(N, N) => true
  rule sameName(_, _) => false [owise]

  syntax Bool ::= isIndexOp(Op) [function]
  rule isIndexOp(addIndex(_, _, _)) => true
  rule isIndexOp(removeIndex(_, _)) => true
  rule isIndexOp(renameIndex(_, _, _)) => true
  rule isIndexOp(otherOp(_)) => false

  syntax String ::= modelOf(Op) [function]
  rule modelOf(addIndex(M, _, _)) => M
  rule modelOf(removeIndex(M, _)) => M
  rule modelOf(renameIndex(M, _, _)) => M

  syntax Bool ::= referencesModel(Op, String) [function]
  rule referencesModel(addIndex(M, _, _), Q) => sameModel(M, Q)
  rule referencesModel(removeIndex(M, _), Q) => sameModel(M, Q)
  rule referencesModel(renameIndex(M, _, _), Q) => sameModel(M, Q)
  rule referencesModel(otherOp(B), _) => B

  syntax ReduceResult ::= reduce(Op, Op) [function]

  // SPEC-PROVENANCE:
  // - from_prompt: "Reduce Add/RemoveIndex migration operations." =>
  //   AddIndex followed by matching RemoveIndex is a no-op.
  rule reduce(addIndex(M, N, P), removeIndex(M2, N2)) => replace(.OpList)
    requires sameModel(M, M2) andBool sameName(N, N2)

  // SPEC-PROVENANCE:
  // - from_prompt: "Reduce Add/RemoveIndex migration operations." =>
  //   A rename of the newly added index preserves the same add/remove lifecycle
  //   and must not block later RemoveIndex cancellation.
  // - from_code: Index.clone() preserves payload while assigning new_name.
  rule reduce(addIndex(M, N, P), renameIndex(M2, New, someName(Old)))
      => replace(addIndex(M, New, P), .OpList)
    requires sameModel(M, M2) andBool sameName(N, Old)

  // SPEC-PROVENANCE:
  // - from_code: MigrationOptimizer scans across operations whose reduce()
  //   result is True; ModelOperation uses the same references_model pattern.
  rule reduce(I, O) => cross(true)
    requires isIndexOp(I) andBool notBool referencesModel(O, modelOf(I))

  rule reduce(_, _) => cross(false) [owise]
endmodule
