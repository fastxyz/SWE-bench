# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## V2 decision

Keep V1 source unchanged.

Reason: the FVK audit found the central issue obligation in PO-NS-PACKAGE and
PO-PATH-DISCOVERY, and V1 discharges both by removing the stale `__file__`
predicate while preserving the `__path__` package guard and path-based
discovery. No source-level finding remains open.

## Decisions

1. Do not reintroduce any `__file__` fallback or special namespace branch.

   Trace: F-001, PO-NS-PACKAGE, PO-PATH-DISCOVERY.

   Rationale: a special namespace branch would duplicate the existing
   `pkgutil.iter_modules(module.__path__)` discovery path. The issue says the
   `__file__` check is obsolete, not that namespace packages need separate
   discovery semantics.

2. Do not broaden the fix to migration writer or questioner code.

   Trace: F-005, PO-COMPAT.

   Rationale: the writer already has an app-relative fallback for packages
   whose directory cannot be resolved, and the questioner already handles a
   module with `__path__` and no `__file__`. The audited migrate failure is in
   loader classification.

3. Do not modify public tests.

   Trace: F-002.

   Rationale: the task forbids test edits. The existing namespace-directory
   loader expectation is suspect legacy evidence under the FVK intent-evidence
   rules and should not drive source behavior.

4. Keep compatibility frame conditions narrow.

   Trace: F-003, F-004, F-005, PO-NONPACKAGE, PO-DISABLED, PO-MISSING,
   PO-COMPAT.

   Rationale: V1 changes only the intended namespace-package classification.
   Disabled migrations, accepted missing modules, non-package modules, import
   errors, migration class validation, and public attribute shapes remain
   unchanged.

## Suggested future checks

When an execution environment is available, run Django's migration loader and
management command tests with a new public case for a migrations directory
without `__init__.py` that contains at least one migration file. Separately, run
the K commands listed in `PROOF.md` if the FVK skeleton is promoted to a
machine-checkable artifact.
