requires "mini-python-stratified-kfold.k"

module STRATIFIED-KFOLD-SPEC
  imports MINI-PYTHON-STRATIFIED-KFOLD

  // SPEC-PROVENANCE:
  // - from_prompt: "shuffle each stratification" => classes must not all reuse
  //   the same per-class permutation draw when shuffle=True.
  // - from_hint: "shuffling each stratification in the same way (i.e, with the
  //   same random state)" => integer seed must be normalized once, then shared.
  // - from_code: V1 passes one check_random_state result to every per-class
  //   KFold instance.
  claim
    <k> makeTestFolds(true, intSeed(S:Int), count(N:Int) count(N:Int) .Counts)
      => draw(S, 0, N) draw(S, 1, N) .Perms
    </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: fixed pairings such as 1 with 11 are the legacy symptom.
  // - from_hint: every class was shuffled "with the same random state."
  // This claim localizes the pre-fix bug; it is not an accepted postcondition.
  claim
    <k> legacyMakeTestFolds(true, intSeed(S:Int), count(N:Int) count(N:Int) .Counts)
      => draw(S, 0, N) draw(S, 0, N) .Perms
    </k>
    requires N >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: random_state is used only when shuffle=True.
  // - from_frame: non-shuffled StratifiedKFold ordering should be preserved.
  claim
    <k> makeTestFolds(false, intSeed(S:Int), count(N1:Int) count(N2:Int) .Counts)
      => ordered(N1) ordered(N2) .Perms
    </k>
    requires N1 >=Int 0 andBool N2 >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_tests: RandomState instances are stateful and often produce
  //   different splits across calls.
  // - from_check_random_state: a RandomState instance is returned as itself.
  claim
    <k> makeTestFolds(true, rngObj(S:Int, D:Int), count(N1:Int) count(N2:Int) .Counts)
      => draw(S, D, N1) draw(S, D +Int 1, N2) .Perms
    </k>
    requires N1 >=Int 0 andBool N2 >=Int 0
    [all-path]
endmodule
