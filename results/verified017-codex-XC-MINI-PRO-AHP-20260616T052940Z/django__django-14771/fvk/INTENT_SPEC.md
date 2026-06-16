# Intent Spec

Status: constructed for FVK; not machine-checked.

## Required Behavior

1. When Django's autoreloader relaunches a child process through `sys.executable`,
   it must preserve CPython `-X` interpreter options from the parent process.

2. The concrete reported case is `python -X utf8 manage.py runserver ...` on
   Windows. The reloader child must continue to run with UTF-8 mode so file
   opening behavior stays consistent with the original process.

3. Preserving `-X` options must not remove existing interpreter warning-option
   preservation or alter the public launch shape for module, script, and
   script-entrypoint relaunches.

4. If the current interpreter doesn't expose `sys._xoptions`, Django has no
   public in-process `-X` option ledger to replay, so no `-X` arguments are
   required.

5. The direct Windows `.exe` shim fallback is outside the reported
   `python -X ... manage.py` path because it intentionally bypasses
   `sys.executable`; this audit preserves the existing fallback behavior.

## Default-Domain Assumptions

- `sys._xoptions` is the public issue's referenced source for CPython `-X`
  options inside the running process.
- A CPython short option with its argument attached, such as `-Xutf8`, is an
  equivalent child-process representation of `-X utf8`.
- The proof is partial correctness over argv construction. It does not prove
  process creation, filesystem checks, or Python interpreter option parsing.
