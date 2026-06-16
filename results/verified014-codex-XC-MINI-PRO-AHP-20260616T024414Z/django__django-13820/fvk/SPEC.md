# SPEC

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

The audited unit is the post-import classification inside
`MigrationLoader.load_disk()` for a migrations module that imported
successfully. The observable being specified is whether the loader marks the app
as `unmigrated` or proceeds to scan `module.__path__` for migration modules.

The surrounding app loop, `MIGRATION_MODULES` lookup, import-error handling,
reload, and actual `pkgutil.iter_modules()` enumeration are framed as unchanged
behavior. They are outside the issue-specific predicate because the V1 patch
only changes the no-namespace-package guard at
`repo/django/db/migrations/loader.py:91`.

## Intent Spec

I1. A regular migrations package must be scanned even when the import system
omits `__file__`.

Evidence: `benchmark/PROBLEM.md` says, "Permit migrations in non-namespace
packages that don't have __file__" and explains that frozen environments may
not set `__file__` on regular packages.

I2. PEP 420 namespace packages must still be rejected as migrations packages.

Evidence: `benchmark/PROBLEM.md` says, "I am NOT asking to allow namespace
packages for apps' migrations" and says namespace packages do not use an
ordinary list for `__path__`.

I3. Normal Python-environment behavior must not change.

Evidence: `benchmark/PROBLEM.md` says the proposal "does not change Django's
behavior at all for normal Python environments."

I4. A module that is not a package must not be scanned as a migrations package.

Evidence: the source comment at `loader.py:100` says, "Module is not a package
(e.g. migrations.py)." The public test `test_load_module_file` expects a
migrations module file to be in `unmigrated_apps`.

I5. An empty namespace migrations directory remains unmigrated.

Evidence: the public test `test_load_empty_dir` expects a missing-`__init__.py`
migrations namespace not to be treated as migrated.

## State Model

The formal model abstracts the imported module into two observable attributes:

- `FileState`: `fileMissing` means `getattr(module, '__file__', None) is None`;
  `fileSet` means the first guard is false.
- `PathKind`: `pathList` means `isinstance(getattr(module, '__path__', None),
  list)`; `pathAbsent` means the module has no `__path__`; `pathOther` means it
  has a non-list path object, including the PEP 420 namespace-package case
  identified by the issue.

The action `scan` abstracts adding the label to `migrated_apps` and calling
`pkgutil.iter_modules(module.__path__)`. The action `unmigrated` abstracts
adding the label to `unmigrated_apps` and continuing to the next app.

## Decision Table

| Case | FileState | PathKind | Required action | Provenance |
| --- | --- | --- | --- | --- |
| C1 | `fileMissing` | `pathList` | `scan` | I1 |
| C2 | `fileMissing` | `pathOther` | `unmigrated` | I2, I5 |
| C3 | `fileMissing` | `pathAbsent` | `unmigrated` | I4 |
| C4 | `fileSet` | `pathAbsent` | `unmigrated` | I4 |
| C5 | `fileSet` | `pathList` | `scan` | I3 |

`fileSet` plus `pathOther` is intentionally not used to justify the issue fix:
the public issue defines the relevant namespace signal as missing `__file__`
plus non-list `__path__`, and V1 preserves the pre-existing scan behavior for
objects that have `__file__`.

## Formal Core

The constructed mini semantics is in `fvk/mini-migration-loader.k`. The
constructed K claims are in `fvk/migration-loader-spec.k`. They enumerate C1
through C5 as reachability claims over `decide(FileState, PathKind)`.

Exact commands to machine-check later, not executed here:

```sh
# From fvk/
kompile mini-migration-loader.k --backend haskell
kprove migration-loader-spec.k
```

## Adequacy Audit

The formal claims are intentionally no stronger than the public intent for the
issue. C1 is the newly required frozen-environment behavior. C2 preserves the
explicit "do not allow namespace packages" requirement. C3 and C4 preserve the
non-package behavior named by code comments and public tests. C5 preserves
normal package scanning. No claim relies on hidden tests or on the V1
implementation as the sole source of expected behavior.

## Compatibility Audit

V1 changes no public function signature, return type, setting name, migration
file format, or virtual dispatch contract. `MigrationLoader.load_disk()` still
populates `disk_migrations`, `unmigrated_apps`, and `migrated_apps`; the only
changed classification is C1.
