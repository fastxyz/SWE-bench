requires "mini-python-router.k"

module MAKEMIGRATIONS-ROUTER-SPEC
  imports MINI-PYTHON-ROUTER

  // SPEC-PROVENANCE:
  // - from_problem: "for each app with the app's models" => new pair stream
  //   must use each app config's own model list.
  // - from_problem: "passing invalid combinations for shards" => every
  //   observable router pair must satisfy validPair.
  // - from_code: any() short-circuits, so runtime may observe a prefix; the
  //   generated stream itself contains every valid pair.
  claim <k> emitNewPairs(APPS:List) => PAIRS:List </k>
    ensures allValid(APPS, PAIRS) ==K true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: old behavior paired every app label with all project
  //   models; this claim records the abstract mechanism of the defect.
  claim <k> emitOldPairs(APPS:List) => PAIRS:List </k>
    ensures PAIRS ==K oldPairs(APPS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_comment: "At least one model must be migrated to the database"
  //   => the consistency-history gate is existential over the valid pair stream.
  claim <k> anyAllowed(ALIAS:String, newPairs(APPS:List)) => RESULT:Bool </k>
    ensures RESULT ==K anyAllowed(ALIAS, newPairs(APPS))
    [all-path]
endmodule
