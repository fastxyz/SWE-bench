requires "mini-pytest-unittest.k"

module PYTEST-UNITTEST-TEARDOWN-SPEC
  imports MINI-PYTEST-UNITTEST
  imports BOOL
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "I would have expected the test to be skipped, even with --pdb."
  //   => if unittest reports a decorator skip before reaching tearDown, pytest's
  //      delayed-teardown slot must remain empty and no delayed tearDown call may run.
  // - from_code: V1 records _explicit_tearDown only in the replacement tearDown
  //   function, which unittest calls only when it reaches its own teardown phase.
  claim [SKIPPED-UNDER-PDB]:
       <k> setup ~> runtest(true, false) ~> teardown => .K </k>
       <explicit> (_:Slot) => none </explicit>
       <delayedCalls> C:Int => C </delayedCalls>
    requires C >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_pdb_teardown_called expects tearDown for passing
  //   unittest tests under --pdb to run eventually.
  // - from_code_comment: "when --pdb is given, we want to postpone calling
  //   tearDown()" to keep instance variables available for postmortem debugging.
  // - from_code: the replacement tearDown stores the original bound method in
  //   _explicit_tearDown when unittest reaches tearDown.
  claim [REACHED-TEARDOWN-UNDER-PDB]:
       <k> setup ~> runtest(true, true) ~> teardown => .K </k>
       <explicit> (_:Slot) => none </explicit>
       <delayedCalls> C:Int => C +Int 1 </delayedCalls>
    requires C >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the non-pdb run was already "properly skipped"; the regression
  //   is specific to --pdb.
  // - frame condition: without --pdb, pytest must not add a delayed-teardown call.
  claim [NO-PDB-NO-DELAYED-CALL]:
       <k> setup ~> runtest(false, UTCalls:Bool) ~> teardown => .K </k>
       <explicit> (_:Slot) => none </explicit>
       <delayedCalls> C:Int => C </delayedCalls>
    requires C >=Int 0
    [all-path]
endmodule
