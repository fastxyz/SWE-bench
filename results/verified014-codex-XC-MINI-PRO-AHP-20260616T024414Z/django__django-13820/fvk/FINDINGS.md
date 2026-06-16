# FINDINGS

Status: constructed, not machine-checked. No tests or code were run.

## F-001: V1 resolves the reported frozen-package miss

Input class: imported migrations module with missing `__file__` and list-valued
`__path__`.

Pre-V1 observed behavior: the loader treated missing `__file__` as sufficient
to mark the app unmigrated, so it never searched existing migrations.

Expected behavior: scan the regular package's `__path__`, because the issue
asks Django to permit migrations in non-namespace packages that do not have
`__file__`.

V1 behavior by source reasoning: the first guard is false as a whole because
`not isinstance(..., list)` is false; the module has `__path__`; execution
reaches `self.migrated_apps.add()` and `pkgutil.iter_modules(module.__path__)`.

Related proof obligations: PO-001.

Status: resolved; no further code change required.

## F-002: Namespace-package rejection is preserved

Input class: imported migrations module with missing `__file__` and non-list
`__path__`, the PEP 420 namespace-package shape identified by the issue.

Expected behavior: mark the app unmigrated. The issue explicitly says it is not
asking to allow namespace packages for migrations.

V1 behavior by source reasoning: both halves of the first guard are true, so the
loader adds the app label to `unmigrated_apps` and continues.

Related proof obligations: PO-002.

Status: preserved; no further code change required.

## F-003: Non-package migrations modules remain unmigrated

Input class: imported migrations module without `__path__`, including a
`migrations.py` file.

Expected behavior: mark the app unmigrated. This is supported by the source
comment and public `test_load_module_file`.

V1 behavior by source reasoning: when `__file__` is set, the namespace guard is
skipped and the `not hasattr(module, '__path__')` guard marks the app
unmigrated. When both `__file__` and `__path__` are absent, the first guard also
marks it unmigrated.

Related proof obligations: PO-003 and PO-004.

Status: preserved; no further code change required.

## F-004: Normal package scanning is preserved

Input class: imported migrations module with `__file__` set and list-valued
`__path__`.

Expected behavior: scan for migrations, preserving normal Python-environment
behavior.

V1 behavior by source reasoning: missing-`__file__` guard is false, the module
has `__path__`, and the loader scans the path as before.

Related proof obligations: PO-005.

Status: preserved; no further code change required.

## F-005: No compatibility issue found

Input class: public callers and downstream consumers of `MigrationLoader`.

Expected behavior: no API, setting, return-shape, migration-file, or virtual
dispatch changes for this narrow fix.

V1 behavior by source reasoning: the patch changes only an internal branch
condition in `load_disk()` and does not alter public signatures or data
structures.

Related proof obligations: PO-006 and PO-007.

Status: no compatibility-driven code change required.

## Residual Risk

The K claims are constructed but not machine-checked. The abstraction assumes
the issue's documented discriminator: regular packages expose ordinary
list-valued `__path__`, while namespace packages use a non-list path object.
No tests were run because the benchmark forbids execution.
