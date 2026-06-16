# Public Compatibility Audit

Status: pass.

## Changed public symbols

`sphinx.domains.python.PyXrefMixin.make_xref`

- Signature: unchanged.
- Return shape: still returns a docutils/Sphinx node from the superclass path.
- Behavioral compatibility: preserves `.` and `~` prefix display/target handling;
  changes only the `refspecific` flag for ordinary and tilde-only field targets.
- Public callsites: `PyField`, `PyGroupedField`, and `PyTypedField` inherit this
  behavior. No caller signature or argument shape changes.

`sphinx.domains.python.PythonDomain.process_field_xref`

- Signature: matches the base `Domain.process_field_xref(pnode)` hook.
- Dispatch compatibility: `Field.make_xref()` already calls this hook when an
  environment is available, so adding a Python override does not require caller
  changes.
- Subclass compatibility: no public subclass override in the audited source path
  must accept new arguments.

## Unchanged public boundaries

- `PythonDomain.find_obj()` and `resolve_xref()` signatures and lookup ordering
  are unchanged.
- Explicit Python xref roles still use `PyXRefRole.process_link()`.
- Non-Python domains are unchanged.
- Tests are not edited.
