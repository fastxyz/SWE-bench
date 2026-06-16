# FVK Notes

No source files were changed during the FVK phase. V1 stands because the audit
found all issue-derived proof obligations discharged by the existing V1 code.

The decision to keep the core condition unchanged traces to F-001 and PO-001:
for a regular package with missing `__file__` and list-valued `__path__`, the
patched guard does not mark the app unmigrated and the loader reaches the scan
path.

The decision not to broaden the fix to allow namespace packages traces to F-002
and PO-002. The public issue explicitly rejects namespace migrations packages,
and V1 still marks missing-`__file__` modules with non-list `__path__` as
unmigrated.

The decision not to refactor the non-package handling traces to F-003, PO-003,
and PO-004. Both missing-path shapes remain unmigrated, preserving the source
comment and public module-file behavior without adding unrelated control-flow
changes.

The decision not to edit other migration modules or public APIs traces to F-004,
F-005, PO-005, PO-006, and PO-007. The issue is limited to the loader's
post-import classification predicate, normal package scanning is preserved, and
the patch changes no public signature, setting, return shape, or migration file
format.

No tests or formal tools were run, per the benchmark constraints. The FVK proof
is constructed, not machine-checked; the exact later-check commands are recorded
in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md`.
