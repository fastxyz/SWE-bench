# FVK Notes

## Source decision

V1 stands unchanged. The FVK audit identified the central source defect as the
old `__file__` gate in `MigrationLoader.load_disk()` and found that V1 already
removed it without disturbing the remaining package guard or discovery path.

Trace:

- `fvk/FINDINGS.md` F-001 records the resolved namespace-package bug.
- `fvk/PROOF_OBLIGATIONS.md` PO-NS-PACKAGE is discharged because there is no
  remaining `__file__` guard before `migrated_apps.add()`.
- `fvk/PROOF_OBLIGATIONS.md` PO-PATH-DISCOVERY is discharged because
  `pkgutil.iter_modules(module.__path__)` is unchanged and now reachable for
  namespace packages.

## Decisions

I did not add a special namespace-package branch. F-001 and PO-PATH-DISCOVERY
show that the intended behavior is the same discovery path for regular and
namespace packages; a special branch would duplicate logic without adding an
intent-backed behavior.

I did not edit `repo/django/db/migrations/questioner.py` or
`repo/django/db/migrations/writer.py`. F-005 and PO-COMPAT found no public
compatibility break, and the proof obligations for the reported migrate failure
localize to loader classification rather than migration file creation or
question prompting.

I did not modify tests. F-002 marks the existing namespace-directory loader test
as suspect legacy evidence because it conflicts with the public issue intent,
and the task forbids test edits.

I kept the compatibility frame narrow. F-003, F-004, PO-NONPACKAGE,
PO-DISABLED, and PO-MISSING confirm that non-package modules, disabled
migrations, accepted missing modules, and unrelated import errors preserve their
existing behavior.

## Verification caveat

No tests, Python code, or K tooling were run, per the task constraints. F-006
records that the proof is constructed but not machine-checked; the commands to
run later are listed in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.
