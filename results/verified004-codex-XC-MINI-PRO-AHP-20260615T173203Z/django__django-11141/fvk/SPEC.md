# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change for `django__django-11141`: the behavior of
`MigrationLoader.load_disk()` when an app's migrations module imports as a
namespace package without `__file__`.

The audited observable is the loader state after scanning apps:
`migrated_apps`, `unmigrated_apps`, and `disk_migrations`. This is the right
observable because `migrate`, `showmigrations`, `sqlmigrate`, and
`MigrationExecutor` consume those attributes.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| S-001 | `benchmark/PROBLEM.md`: "Allow migrations directories without __init__.py files." | Namespace migrations packages are valid migrations packages. |
| S-002 | `benchmark/PROBLEM.md`: "a package with no __init__.py is implicitly a namespace package, so it has no __file__ attribute." | Absence of `__file__` is not a valid rejection reason. |
| S-003 | `benchmark/PROBLEM.md`: "`pkgutil.iter_modules()` uses the package's `__path__` list" | Discovery must be based on `module.__path__`. |
| S-004 | `benchmark/PROBLEM.md`: "`__file__` check is no longer needed" | The loader must not preserve an equivalent file-based gate. |
| S-005 | Source comment: "Module is not a package (e.g. migrations.py)." | Modules without `__path__` remain unmigrated. |
| S-006 | `migrate` checks `executor.loader.migrated_apps`. | Classification of namespace migrations packages must be user-visible to `migrate`. |

## Domain

In-domain inputs are installed app configurations whose migration module is:

- disabled via `MIGRATION_MODULES[app_label] = None`;
- absent under the existing missing-module rules;
- imported successfully as a non-package module without `__path__`;
- imported successfully as a regular package with `__path__`;
- imported successfully as an implicit namespace package with `__path__` and no
  usable `__file__`.

The proof is partial correctness over the per-app classification and discovery
step. It does not prove termination of Python import machinery or correctness of
third-party import hooks.

## Formal Model

The `.k` core is:

- `fvk/mini-loader.k`: a property-complete abstraction of the loader branch that
  matters for this issue.
- `fvk/migration-loader-spec.k`: K claims for migrated/unmigrated classification
  and the namespace package case.

The abstraction preserves the property axis under audit:

- `HAS_PATH` models `hasattr(module, '__path__')`.
- `HAS_FILE` models whether `module.__file__` exists or is non-`None`.
- `PATH_ENTRIES` models the results returned by
  `pkgutil.iter_modules(module.__path__)`.
- `Decision` models the observable classification and discovered migration
  names.

Passing and failing discriminator:

- Passing instance: `loaded(HAS_PATH=true, HAS_FILE=false, ENTRIES=[0001])`
  must map to `migrated({0001})`.
- Failing legacy instance: the same module mapped to `unmigrated` when the
  `__file__` gate was present.

Because the abstraction distinguishes those two outcomes, it does not collapse
the defect.

## Claims

PO-NS-PACKAGE. If a migrations module imports and has `__path__`, then it is a
migrated app even when `__file__` is absent or `None`.

PO-PATH-DISCOVERY. Migration names are discovered from `module.__path__` by the
existing `pkgutil.iter_modules()` filter.

PO-NONPACKAGE. If a migrations module imports but lacks `__path__`, it remains
unmigrated.

PO-DISABLED. Disabled migrations remain unmigrated.

PO-MISSING. Existing accepted missing-module cases remain unmigrated.

PO-COMPAT. Public API shape and downstream consumers of loader state remain
compatible.

## Adequacy Summary

The formal English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the
intent-only obligations in `INTENT_SPEC.md`; `SPEC_AUDIT.md` records all entries
as pass. The only conflicting public evidence is the existing in-repo loader
test that encodes the old rejection of an empty namespace directory; per FVK's
intent-evidence rules, it is marked suspect rather than used as an oracle.
