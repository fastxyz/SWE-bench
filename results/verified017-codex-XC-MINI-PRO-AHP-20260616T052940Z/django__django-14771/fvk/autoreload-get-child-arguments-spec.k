requires "mini-python-autoreload.k"

module AUTORELOAD-GET-CHILD-ARGUMENTS-SPEC
  imports MINI-PYTHON-AUTORELOAD
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "Auto-reloader should pass -X options" => child argv must include
  //   every CPython -X option when the child is launched through sys.executable.
  // - from_prompt: reproduction shows "python -X utf8 manage.py runserver" changing
  //   from UTF-8 to cp936 after reload => ordinary script relaunch is in-domain.
  // - from_code: get_child_arguments() prepends sys.executable, warning options,
  //   interpreter options, and then the script path plus user argv.
  claim
    <k> childArgs(EXE:String, WARNS:Warns, true, XOPTS:XOpts, asScript(SCRIPT:String), USER:Args)
      => arg(EXE, append(warnArgs(WARNS), append(xArgs(true, XOPTS), scriptArgs(SCRIPT, USER)))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Auto-reloader should pass -X options" => module relaunch must
  //   preserve xoptions before the -m target and user arguments.
  // - from_code: the __main__.__spec__ branch appends "-m", module name, then sys.argv[1:].
  claim
    <k> childArgs(EXE:String, WARNS:Warns, true, XOPTS:XOpts, asModule(NAME:String), USER:Args)
      => arg(EXE, append(warnArgs(WARNS), append(xArgs(true, XOPTS), moduleArgs(NAME, USER)))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: interpreter -X options are attached to the Python executable,
  //   not to Django command arguments.
  // - from_code: the django-admin-script.py fallback still uses sys.executable.
  claim
    <k> childArgs(EXE:String, WARNS:Warns, true, XOPTS:XOpts, asScriptEntrypoint(SCRIPT:String), USER:Args)
      => arg(EXE, append(warnArgs(WARNS), append(xArgs(true, XOPTS), scriptArgs(SCRIPT, USER)))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: CPython sys._xoptions represents "-X name" as a flag-like
  //   option and "-X name=value" as a value-like option.
  // - from_code: V1 formats True as "-X<key>" and non-True values as "-X<key>=<value>".
  claim
    <k> xArgs(true, xopt(KEY:String, flag, REST:XOpts))
      => arg("-X" +String KEY, xArgs(true, REST)) </k>
    [all-path]

  claim
    <k> xArgs(true, xopt(KEY:String, val(V:String), REST:XOpts))
      => arg("-X" +String KEY +String "=" +String V, xArgs(true, REST)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: an interpreter without sys._xoptions has no in-process
  //   -X option ledger to replay.
  // - from_code: hasattr(sys, "_xoptions") gates xoption replay.
  claim
    <k> childArgs(EXE:String, WARNS:Warns, false, XOPTS:XOpts, asScript(SCRIPT:String), USER:Args)
      => arg(EXE, append(warnArgs(WARNS), scriptArgs(SCRIPT, USER))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/public tests: the direct .exe fallback bypasses sys.executable and
  //   returns the executable shim plus user arguments.
  // - audit note: this is outside the reported "python -X ... manage.py" path.
  claim
    <k> childArgs(EXE:String, WARNS:Warns, HASX:Bool, XOPTS:XOpts, asExeEntrypoint(ENTRY:String), USER:Args)
      => arg(ENTRY, USER) </k>
    [all-path]
endmodule
