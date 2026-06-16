requires "mini-autoreload.k"

module GET-CHILD-ARGUMENTS-SPEC
  imports MINI-AUTORELOAD

  // SPEC-PROVENANCE:
  // - from_prompt: "Allow autoreloading of `python -m pkg_other_than_django runserver`"
  //   => preserve the package name from __main__.__spec__.parent.
  // - from_prompt: "Following this algorithm ... avoiding use of __file__"
  //   => do not compare sys.argv[0] with django.__main__.__file__.
  // - from_code: sys.warnoptions are prepended as "-W..." before command args.
  claim <k> getChildArguments(EXE, WARN, ListItem(SCRIPT) ARGVREST, parent(P), SCRIPTEXISTS, EXEFALLBACK, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ListItem("-m") ListItem(P) ARGVREST) ... </k>
    requires P =/=String ""
    [label(PACKAGE_MAIN), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: directory/zip execution has empty parent, not a package -m form.
  // - from_public_tests: warning options and script restart behavior are preserved.
  claim <k> getChildArguments(EXE, WARN, ListItem(SCRIPT) ARGVREST, noParent(), true, EXEFALLBACK, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ListItem(SCRIPT) ARGVREST) ... </k>
    [label(SCRIPT_EXISTS), all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: Windows .exe entrypoint fallback is preserved.
  claim <k> getChildArguments(EXE, WARN, ListItem(SCRIPT) ARGVREST, noParent(), false, true, SCRIPTFALLBACK, EXEPATH, SCRIPTPATH)
        => returned(ListItem(EXEPATH) ARGVREST) ... </k>
    [label(EXE_FALLBACK), all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: Windows -script.py entrypoint fallback is preserved.
  claim <k> getChildArguments(EXE, WARN, ListItem(SCRIPT) ARGVREST, noParent(), false, false, true, EXEPATH, SCRIPTPATH)
        => returned(pythonPrefix(EXE, WARN) ListItem(SCRIPTPATH) ARGVREST) ... </k>
    [label(SCRIPT_FALLBACK), all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: missing script with no fallback raises RuntimeError.
  claim <k> getChildArguments(EXE, WARN, ListItem(SCRIPT) ARGVREST, noParent(), false, false, false, EXEPATH, SCRIPTPATH)
        => runtimeError("Script " +String SCRIPT +String " does not exist.") ... </k>
    [label(MISSING_SCRIPT), all-path]
endmodule
