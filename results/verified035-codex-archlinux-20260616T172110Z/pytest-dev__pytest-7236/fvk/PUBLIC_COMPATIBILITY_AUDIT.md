# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`repo/src/_pytest/unittest.py::TestCaseFunction.runtest`

Change: under `--pdb`, V1 stores the original bound `tearDown` method in a
local closure and installs an instance-level replacement that records
`_explicit_tearDown` only when called.

Compatibility result: pass.

Reasoning:

- The method signature of `TestCaseFunction.runtest` is unchanged.
- The `TestCaseFunction.teardown` signature and pytest hook/result callback
  signatures are unchanged.
- The replacement instance `tearDown` accepts `*args, **kwargs`, which is at
  least as permissive as the previous V1-predecessor no-op replacement that
  accepted only `*args`.
- `_explicit_tearDown` remains a private implementation detail. A repository
  search found no other source uses outside `TestCaseFunction`.
- Public unittest `TestCase.tearDown` semantics are preserved by forwarding the
  real bound method later only when unittest actually called the replacement.

No public caller, subclass override, hook implementation, or producer/consumer
shape needs a source change.
