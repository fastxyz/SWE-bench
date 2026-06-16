requires "mini-cli.k"

module CLI-VERBOSE-SPEC
  imports MINI-CLI

  // SPEC-PROVENANCE:
  // - from_prompt: "-v" should have "Similar behaviour to the long option"
  //   => short verbose sets verbose mode and consumes no value.
  // - from_code: V2 maps "-v" to (False, _set_verbose_mode).
  claim
    <k> preprocess(shortVerbose() ; REST:Args) => preprocess(REST) ... </k>
    <verbose> false => true </verbose>
    <out> OUT:Args </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: command used was "pylint mytest.py -v"
  //   => a file/path argument before -v is preserved.
  // - from_code: non-preprocessable args are appended unchanged.
  claim
    <k> preprocess(other("mytest.py") ; shortVerbose() ; .Args) => done ... </k>
    <verbose> false => true </verbose>
    <out> .Args => other("mytest.py") ; .Args </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: verbose does not expect an argument
  //   => inline short-option value is rejected.
  // - from_code: not-takearg options with value raise ArgumentPreprocessingError.
  claim
    <k> preprocess(shortVerboseValue("true") ; .Args)
      => error("Option -v doesn't expects a value") ... </k>
    <verbose> false </verbose>
    <out> .Args </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: "--" ends command-line option processing.
  // - from_code: V2 appends args[i:] and breaks when argument == "--".
  claim
    <k> preprocess(separator() ; shortVerbose() ; REST:Args) => done ... </k>
    <verbose> false </verbose>
    <out> .Args => separator() ; shortVerbose() ; REST </out>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: help must not suggest VERBOSE value
  //   => verbose argparse metadata has nargs 0.
  // - from_code: verbose option descriptor has kwargs {"nargs": 0}.
  claim
    <k> verboseNargs() => 0 ... </k>
    [all-path]
endmodule
