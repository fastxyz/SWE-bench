# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-NS-PACKAGE

Statement: for every imported migrations module with `hasattr(module,
'__path__') == True`, the app is added to `migrated_apps` and not to
`unmigrated_apps`, regardless of whether `getattr(module, '__file__', None)` is
truthy.

Public evidence: S-001 through S-004.

V1 status: discharged by code inspection. The only branch between successful
import and `self.migrated_apps.add(app_config.label)` is now the `__path__`
guard. There is no remaining `__file__` guard in `load_disk()`.

Finding trace: F-001, F-002.

## PO-PATH-DISCOVERY

Statement: for migrated packages, migration names are computed from
`pkgutil.iter_modules(module.__path__)`, including namespace packages whose only
location information is `__path__`.

Public evidence: S-003.

V1 status: discharged by code inspection. V1 reaches the existing
`pkgutil.iter_modules(module.__path__)` expression for any imported module with
`__path__`.

Finding trace: F-001.

## PO-FILTER

Statement: the existing name filter is preserved: include entries where
`is_pkg` is false and `name[0]` is neither `_` nor `~`.

Public evidence: implementation-preservation obligation S-005 and unchanged
source behavior.

V1 status: discharged by unchanged source. The set comprehension over
`pkgutil.iter_modules(module.__path__)` is untouched.

Finding trace: F-001.

## PO-NONPACKAGE

Statement: a successfully imported migrations module without `__path__` is
classified as unmigrated.

Public evidence: S-005.

V1 status: discharged by unchanged guard:
`if not hasattr(module, '__path__'): self.unmigrated_apps.add(...)`.

Finding trace: F-003.

## PO-DISABLED

Statement: when `migrations_module()` returns `None`, the app is classified as
unmigrated and no import or discovery is attempted.

Public evidence: existing `MIGRATION_MODULES` contract and implementation
preservation.

V1 status: discharged by unchanged source before import.

Finding trace: F-004.

## PO-MISSING

Statement: existing accepted missing-module cases are classified as unmigrated,
while unrelated import errors still propagate.

Public evidence: implementation-preservation obligation for behavior outside
the issue.

V1 status: discharged by unchanged `except ImportError` branch.

Finding trace: F-004.

## PO-MIGRATE-CONSUMER

Statement: downstream `migrate` behavior follows from loader classification:
namespace migrations packages must be visible through `migrated_apps`, not
`unmigrated_apps`.

Public evidence: S-006.

V1 status: discharged because PO-NS-PACKAGE moves namespace packages to
`migrated_apps`, and V1 does not alter the consumer API.

Finding trace: F-001, F-005.

## PO-COMPAT

Statement: no public method signatures, return shapes, or attribute shapes
change.

Public evidence: compatibility audit.

V1 status: discharged by code inspection; the edit removes a branch only.

Finding trace: F-005.

## Machine-check commands not executed

The commands that would machine-check the constructed artifacts are:

```sh
kompile fvk/mini-loader.k --backend haskell
kast --backend haskell fvk/migration-loader-spec.k
kprove fvk/migration-loader-spec.k
```

Expected outcome: `kprove` reduces the claims to `#Top`. The commands were not
run because the task forbids K framework tooling.
