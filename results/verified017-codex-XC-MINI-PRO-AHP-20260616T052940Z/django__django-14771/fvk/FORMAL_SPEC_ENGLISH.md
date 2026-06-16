# Formal Spec in English

Status: constructed from `autoreload-get-child-arguments-spec.k`; not
machine-checked.

## Claims

- C1, script relaunch: for any executable, warning options, xoptions, script
  path, and user arguments, a child launched through `sys.executable` as a
  script has argv `executable + warning args + xoption args + script path +
  user args`.

- C2, module relaunch: for any executable, warning options, xoptions, module
  name, and user arguments, a child launched through `sys.executable` with
  `-m` has argv `executable + warning args + xoption args + "-m" + module name
  + user args`.

- C3, script-entrypoint fallback: if the missing `sys.argv[0]` path resolves to
  a `*-script.py` file, the child still uses `sys.executable`, so warning args
  and xoption args precede the script-entrypoint path and user args.

- C4, flag xoption formatting: an xoption whose value is the flag marker is
  emitted as one attached CPython short option argument, `-X<key>`.

- C5, value xoption formatting: an xoption with an explicit value is emitted as
  one attached CPython short option argument, `-X<key>=<value>`.

- C6, no xoption ledger: if the interpreter exposes no `_xoptions` ledger, the
  child argv contains warning args and normal launch arguments but no `-X`
  replay.

- C7, direct `.exe` fallback: if Django directly executes a resolved `.exe`
  entrypoint shim, the child argv is the shim path plus user args. Interpreter
  flags are not replayed because this path doesn't launch through
  `sys.executable`.

## Frame Conditions

- The function signature and return type are unchanged.
- Existing warning-option replay remains before Django's module or script
  arguments.
- Existing module, script, script-entrypoint, direct `.exe`, and missing-script
  branch structure is unchanged except for adding `-X` replay to Python-exec
  branches.
