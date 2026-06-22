# FVK Notes

## Decisions

V2 changes V1 by reverting the `BaseModelAdmin.to_field_allowed()` edit.

Trace: `fvk/FINDINGS.md` F-001 showed that V1 called
`admin.get_inlines(request)` in a path with no `obj` context. For object-
dependent inline hooks, that can omit inline classes that are still present in
static `admin.inlines`. `fvk/PROOF_OBLIGATIONS.md` PO-004 therefore requires
`to_field_allowed()` to keep using static `admin.inlines`. The source now
matches PO-004.

V2 keeps `ModelAdmin.get_inlines(request, obj=None)`.

Trace: PO-001 requires the additive hook and the public issue explicitly names
that signature. The default implementation returns `self.inlines`, preserving
old static behavior.

V2 keeps `ModelAdmin.get_inline_instances()` delegating to
`self.get_inlines(request, obj)`.

Trace: PO-002 requires the instance-construction path to use hook-selected
inline classes. PO-003 requires the rest of the loop to remain unchanged, which
keeps instantiation, permission filtering, and `max_num = 0` behavior intact.

No change was made to `django.contrib.admin.checks.py`.

Trace: F-003 and PO-006 classify static checks as the correct frame condition
because checks have no request or object context. The public issue asks for a
runtime request/object hook, not dynamic system checks.

No test files were modified and no tests, Python code, or K tooling were run.

Trace: F-002 records the missing public tests as a test gap, but the task
forbids test edits and execution. `fvk/PROOF.md` records the K commands for a
future machine-checking environment only.

## Final Source State

The final source change is minimal:

- add `ModelAdmin.get_inlines(request, obj=None)`;
- change `get_inline_instances()` to iterate over
  `self.get_inlines(request, obj)`;
- leave related-object validation and admin checks on static `inlines`.
