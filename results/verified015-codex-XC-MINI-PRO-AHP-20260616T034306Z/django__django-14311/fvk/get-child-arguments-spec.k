requires "mini-python-argv.k"

module GET-CHILD-ARGUMENTS-SPEC
  imports MINI-PYTHON-ARGV
  imports LIST
  imports STRING

  // SPEC-PROVENANCE:
  // - E1/E2: python -m custom_module and foo.bar.baz must restart with the
  //   original full module name, not the parent package.
  // - E3: foo.my__main__ is an ordinary module name, not package __main__.
  // Claim: MODULE-SPEC-FULL-NAME
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, moduleSpec(NAME:String), PATH:PathState)
      => args(BASE ListItem("-m") ListItem(NAME) TAIL) </k>
    requires NAME =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4: exact __main__ or .__main__ package entry points restart with
  //   their parent package, preserving python -m django behavior.
  // Claim: PACKAGE-MAIN-USES-PARENT
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, packageMainSpec(PARENT:String), PATH:PathState)
      => args(BASE ListItem("-m") ListItem(PARENT) TAIL) </k>
    requires PARENT =/=String ""
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: a spec that yields no usable -m module name falls through to the
  //   existing script fallback behavior.
  // Claim: EMPTY-SPEC-SCRIPT-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, emptyMainSpec, scriptExists)
      => args(BASE FULL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: absent __spec__ with an existing script path preserves direct
  //   script execution.
  // Claim: NO-SPEC-SCRIPT-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, noSpec, scriptExists)
      => args(BASE FULL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: Windows .exe fallback ignores sys.executable and executes the entry
  //   point directly.
  // Claim: EXE-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, noSpec, exeEntry(EXE:String))
      => args(ListItem(EXE) TAIL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: the same .exe fallback applies when a present spec yields no
  //   usable -m module name.
  // Claim: EMPTY-SPEC-EXE-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, emptyMainSpec, exeEntry(EXE:String))
      => args(ListItem(EXE) TAIL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: Windows -script.py fallback keeps BASE and inserts script_entrypoint.
  // Claim: SCRIPT-ENTRY-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, noSpec, scriptEntry(SCRIPT:String))
      => args(BASE ListItem(SCRIPT) TAIL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: the same -script.py fallback applies when a present spec yields no
  //   usable -m module name.
  // Claim: EMPTY-SPEC-SCRIPT-ENTRY-FALLBACK
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, emptyMainSpec, scriptEntry(SCRIPT:String))
      => args(BASE ListItem(SCRIPT) TAIL) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: missing script with no fallback raises the existing RuntimeError.
  // Claim: MISSING-SCRIPT-ERROR
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, noSpec, missingScript(ARG0:String))
      => runtimeError(ARG0) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: the same missing-script error applies when a present spec yields
  //   no usable -m module name.
  // Claim: EMPTY-SPEC-MISSING-SCRIPT-ERROR
  claim
    <k> childArgs(BASE:List, TAIL:List, FULL:List, emptyMainSpec, missingScript(ARG0:String))
      => runtimeError(ARG0) </k>
    [all-path]
endmodule
