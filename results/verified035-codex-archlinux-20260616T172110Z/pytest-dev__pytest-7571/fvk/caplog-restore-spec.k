requires "mini-caplog.k"

module CAPLOG-RESTORE-SPEC
  imports MINI-CAPLOG

  // SPEC-PROVENANCE:
  // - from_prompt: "The log levels set are restored automatically at the end of the test"
  //   => finalization after caplog.set_level restores logger and handler levels.
  // - from_prompt: second test should print 0, not 42
  //   => the shared handler level must restore to the pre-test value H0.
  claim <k> finalize(setLevel(initialState(H0, G0), L))
        => state(H0, G0, some(H0), some(G0)) </k>

  // SPEC-PROVENANCE:
  // - from public tests and existing logger behavior: repeated set_level calls restore
  //   to the first original value, not the most recent temporary value.
  claim <k> finalize(setLevel(setLevel(initialState(H0, G0), L1), L2))
        => state(H0, G0, some(H0), some(G0)) </k>

  // SPEC-PROVENANCE:
  // - from compatibility audit: tests that only read caplog must not get a new
  //   handler-level write during finalization.
  claim <k> finalize(initialState(H0, G0))
        => state(H0, G0, none, none) </k>

  // SPEC-PROVENANCE:
  // - from docs: caplog.at_level temporarily changes log level only inside the
  //   with block.
  claim <k> atLevel(initialState(H0, G0), L)
        => state(H0, G0, none, none) </k>
endmodule
