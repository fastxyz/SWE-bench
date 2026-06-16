# Public Compatibility Audit

Status: constructed; not machine-checked.

## Changed Symbol

`django.utils.autoreload.get_child_arguments()`

- Signature: unchanged.
- Return type: unchanged list-like argv sequence.
- Callers: `restart_with_reloader()` continues to call the function without
  arguments and pass the resulting argv to `subprocess.run()`.
- Public tests/callsites found in allowed source: existing tests exercise
  module, script, script-entrypoint, direct `.exe`, and missing-script branches.
  The intended new behavior only adds interpreter `-X` arguments when an
  `_xoptions` ledger exists and the child uses `sys.executable`.

## Compatibility Verdict

No public API, method dispatch, override, or producer/consumer shape is changed.
The only observable argv change is the intended replay of CPython `-X`
interpreter options on Python-executable relaunch paths.
