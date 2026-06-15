# FINDINGS

Status: constructed, not machine-checked.

## F-001: V1 removes the operative namespace-package bug

Classification: resolved code bug.

Input: a migrations module that imports successfully, has `__path__`, and has
no usable `__file__`, such as an implicit namespace package created by a
migrations directory without `__init__.py`.

Pre-V1 observed behavior by code inspection: `MigrationLoader.load_disk()`
classified the app as unmigrated at the `getattr(module, '__file__', None) is
None` branch, so `migrate app_label` could report that the app did not have
migrations even though discovery from `__path__` was possible.

Expected behavior from S-001 through S-004: classify the app as migrated and
discover migration modules from `module.__path__`.

V1 status: resolved. The stale `__file__` branch is gone, and the existing
`hasattr(module, '__path__')` guard plus `pkgutil.iter_modules(module.__path__)`
now handles namespace packages.

Related proof obligations: PO-NS-PACKAGE, PO-PATH-DISCOVERY.

## F-002: Existing namespace-directory test is suspect legacy evidence

Classification: suspect public-test evidence, not a source bug.

Input: `tests/migrations/test_loader.py::test_load_empty_dir`, which expects a
namespace migrations module to appear in `unmigrated_apps`.

Observed vs expected: the test preserves the pre-fix behavior, while the public
issue says migrations directories without `__init__.py` should be allowed and
the `__file__` check is obsolete.

Decision: do not use this test as an oracle for source behavior. The task also
forbids modifying tests, so no test file was edited.

Related proof obligations: PO-NS-PACKAGE; adequacy audit in `SPEC_AUDIT.md`.

## F-003: Non-package modules remain intentionally unmigrated

Classification: preserved behavior.

Input: a migration module path that imports as a plain module, for example a
`migrations.py` file, and therefore has no `__path__`.

Observed vs expected: V1 still adds the app to `unmigrated_apps` before
discovery. This matches the source comment and avoids treating a module file as
a migrations package.

Related proof obligations: PO-NONPACKAGE.

## F-004: Disabled and missing-module paths are outside the namespace fix and remain unchanged

Classification: preserved behavior.

Input: disabled migrations (`MIGRATION_MODULES[app_label] = None`) or accepted
missing migration modules under the existing `ignore_no_migrations` rules.

Observed vs expected: V1 does not touch these branches; they remain unmigrated.

Related proof obligations: PO-DISABLED, PO-MISSING.

## F-005: No public compatibility break found

Classification: compatibility confirmation.

Input: downstream consumers of `MigrationLoader` in migration management
commands and `MigrationExecutor`.

Observed vs expected: V1 changes only classification for namespace migration
packages. No method signatures, return types, virtual dispatch calls, or
attribute shapes changed.

Related proof obligations: PO-COMPAT.

## F-006: Proof is constructed only

Classification: proof/tooling limitation.

Input: the K artifacts in `fvk/mini-loader.k` and
`fvk/migration-loader-spec.k`.

Observed vs expected: the proof has been reasoned through from the artifacts,
but `kompile`, `kast`, and `kprove` were not run because the task forbids K
tooling execution.

Decision: keep tests until a human or CI environment can machine-check the
claims. This limitation does not identify a source-code change.

Related proof obligations: all.
