# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Model Obligations

The model in `fvk/mini-migration-loader.k` abstracts the patched branch into a
total decision function over the issue-relevant state:

```text
decide(FileState, PathKind) -> Action
```

`FileState` captures the truth of `getattr(module, '__file__', None) is None`.
`PathKind` captures whether `__path__` is absent, a list, or a non-list object.
`Action` is either `scan` or `unmigrated`.

## Source-Level Obligations

### PO-001: Regular package without `__file__` scans

Precondition: import succeeded; `getattr(module, '__file__', None) is None`;
`isinstance(getattr(module, '__path__', None), list)` is true.

Required postcondition: the loader must not mark the app unmigrated at the
namespace guard; it must reach the scan path.

Source discharge: at `loader.py:95-97`, the left side is true and the right side
`not isinstance(..., list)` is false, so the `if` body is skipped. At
`loader.py:101`, the module has `__path__`, so that guard is skipped. Execution
reaches `loader.py:107-109`.

Related finding: F-001.

Status: discharged by V1.

### PO-002: Namespace package remains unmigrated

Precondition: import succeeded; `getattr(module, '__file__', None) is None`;
`getattr(module, '__path__', None)` is present but not a list.

Required postcondition: the loader must add the app to `unmigrated_apps` and
continue without scanning.

Source discharge: both halves of `loader.py:95-96` are true, so
`loader.py:98-99` executes.

Related finding: F-002.

Status: discharged by V1.

### PO-003: Missing `__file__` and absent `__path__` is not scanned

Precondition: import succeeded; `getattr(module, '__file__', None) is None`;
`getattr(module, '__path__', None)` is absent.

Required postcondition: the loader must add the app to `unmigrated_apps` and
continue.

Source discharge: `getattr(module, '__path__', None)` returns `None`, which is
not a list, so the guard at `loader.py:95-97` executes `loader.py:98-99`.

Related finding: F-003.

Status: discharged by V1.

### PO-004: Module file with no package path remains unmigrated

Precondition: import succeeded; `getattr(module, '__file__', None)` is not
`None`; `hasattr(module, '__path__')` is false.

Required postcondition: the loader must add the app to `unmigrated_apps` and
continue.

Source discharge: the missing-`__file__` guard is false. The non-package guard
at `loader.py:101` is true, so `loader.py:102-103` executes.

Related finding: F-003.

Status: discharged by V1.

### PO-005: Normal package scanning remains unchanged

Precondition: import succeeded; `getattr(module, '__file__', None)` is not
`None`; `hasattr(module, '__path__')` is true and `__path__` is a list.

Required postcondition: the loader must scan the package path.

Source discharge: the missing-`__file__` guard is false and the non-package
guard is false. Execution reaches `loader.py:107-109`.

Related finding: F-004.

Status: discharged by V1.

### PO-006: Import and disabled-migration branches are framed

Precondition: `module_name is None`, or `import_module(module_name)` raises the
handled `ModuleNotFoundError` cases.

Required postcondition: behavior remains as before V1.

Source discharge: V1 changed only `loader.py:91-97`; branches at
`loader.py:76-89` are unchanged.

Related finding: F-005.

Status: discharged by diff inspection.

### PO-007: Public compatibility is preserved

Precondition: existing callers instantiate and use `MigrationLoader` and inspect
`disk_migrations`, `unmigrated_apps`, or `migrated_apps`.

Required postcondition: no public signature or result-shape change occurs.

Source discharge: V1 changes no function definition, call signature, attribute
name, migration module naming rule, or migration object construction.

Related finding: F-005.

Status: discharged by source inspection.

## Constructed K Claims

The issue-relevant obligations PO-001 through PO-005 are represented in
`fvk/migration-loader-spec.k` as concrete reachability claims over
`decide(FileState, PathKind)`.

Exact commands to machine-check later, not executed here:

```sh
# From fvk/
kompile mini-migration-loader.k --backend haskell
kprove migration-loader-spec.k
```
