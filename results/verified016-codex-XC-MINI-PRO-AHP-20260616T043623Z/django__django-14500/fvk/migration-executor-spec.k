requires "mini-migrations.k"

module MIGRATION-EXECUTOR-SPEC
  imports MINI-MIGRATIONS
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "Squashed migration is not marked as unapplied" =>
  //   a replacement key must be absent when its replaced set is not fully
  //   applied.
  // - from_prompt: "mark the squash migration as unapplied, too, not only the
  //   replaced migrations" => the replacement key itself is reconciled.
  // - from_code: MigrationLoader marks a replacement applied only when all
  //   replacement targets are applied.
  // - from_code: MigrationRecorder row presence is applied state.
  claim
    <k> checkReplacements => .K </k>
    <applied> A:KeySet => AFinal:KeySet </applied>
    <replacements> RM:ReplacementMap </replacements>
    requires contains(replacementKeys(RM), K:Key)
    ensures contains(AFinal, K) ==Bool allApplied(A, targets(RM, K))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: issue concerns replacement migration bookkeeping only.
  // - from_code: check_replacements() only writes keys from loader.replacements.
  claim
    <k> checkReplacements => .K </k>
    <applied> A:KeySet => AFinal:KeySet </applied>
    <replacements> RM:ReplacementMap </replacements>
    requires notBool contains(replacementKeys(RM), X:Key)
    ensures contains(AFinal, X) ==Bool contains(A, X)
    [all-path]
endmodule
