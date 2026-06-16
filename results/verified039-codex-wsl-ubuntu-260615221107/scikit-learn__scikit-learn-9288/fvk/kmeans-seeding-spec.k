requires "mini-kmeans.k"

module KMEANS-SEEDING-SPEC
  imports MINI-KMEANS

  // SPEC-PROVENANCE:
  // - from_prompt: "Should expect ... inertia ... same regardless of how many
  //   jobs are run in parallel" => public postcondition: serial and parallel
  //   execution choose the same best initialization for fixed inputs.
  // - from_prompt_hint: "n_jobs=1 case gets a different random seed for the
  //   n_init runs than the n_jobs!=1 case" => seed-stream equality is the
  //   required repair mechanism.
  // - from_docs: "n_jobs ... works by computing each of the n_init runs in
  //   parallel" => n_jobs changes scheduling only, not the semantic result.
  // - from_code: V1 computes drawSeeds once before the branch and each branch
  //   uses those seeds in order.
  claim
    <k> kmeans(serial, RNG:Rng, N:Int)
      => chooseBest(mapRun(P:Params, drawSeeds(RNG, N))) ... </k>
    <params> P </params>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the parallel branch maps kmeans_single over the same seed
  //   list and chooses np.argmin(inertia), modeled as chooseBest.
  claim
    <k> kmeans(parallel, RNG:Rng, N:Int)
      => chooseBest(mapRun(P:Params, drawSeeds(RNG, N))) ... </k>
    <params> P </params>
    requires N >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the serial branch keeps the current best result and updates
  //   only when a later inertia is strictly lower.
  // - proof obligation: after consuming any suffix SS, the loop result equals
  //   choosing the best from the existing accumulator plus runSingle over SS.
  claim
    <k> serialLoop(SS:Seeds, B:MaybeResult)
      => bestFrom(B, mapRun(P:Params, SS)) ... </k>
    <params> P </params>
    [all-path]
endmodule
