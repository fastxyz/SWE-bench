# Intent Spec

Status: constructed from public evidence; not machine-checked.

## Target

The audited unit is `MigrationLoader.load_disk()` in
`repo/django/db/migrations/loader.py`, plus its public classification effects
used by `migrate`: `migrated_apps`, `unmigrated_apps`, and `disk_migrations`.

## Intent-derived obligations

I-001. Migration directories without `__init__.py` must be allowed.

Evidence: `benchmark/PROBLEM.md` says, "Allow migrations directories without
__init__.py files."

Obligation: an imported migrations module that is an implicit namespace package
is in-domain and must not be rejected merely because it lacks `__file__`.

I-002. Namespace migration discovery is path-based.

Evidence: `benchmark/PROBLEM.md` says `pkgutil.iter_modules()` uses the
package's `__path__` list, which exists on implicit namespace packages.

Obligation: when the migrations module exposes `__path__`, migration names must
be discovered from that path using the existing `pkgutil.iter_modules()` flow.

I-003. The obsolete `__file__` precondition must not remain.

Evidence: `benchmark/PROBLEM.md` says the `__file__` check "is no longer
needed" and "prevents migrate from working on namespace packages".

Obligation: whether `module.__file__` exists or is `None` must not affect
classification of a package as migrated when `module.__path__` exists.

I-004. Non-packages remain outside migration discovery.

Evidence: code comment and behavior around `migrations.py` in
`MigrationLoader.load_disk()` identify modules without `__path__` as not
packages.

Obligation: a successfully imported migrations module without `__path__` must
still be classified as unmigrated; the namespace fix must not make
`migrations.py` count as a package.

I-005. Existing disabled and missing-module behavior is preserved.

Evidence: `MigrationLoader.migrations_module()` returns `None` for disabled
migrations, and `load_disk()` has explicit missing-module handling controlled by
`ignore_no_migrations`.

Obligation: the namespace fix must not change behavior for disabled migrations,
explicit missing modules, default missing migration modules, stale `.pyc`
errors, or modules without a `Migration` class.

I-006. Public compatibility is preserved.

Evidence: downstream code in `migrate`, `showmigrations`, `squashmigrations`,
`sqlmigrate`, and `MigrationExecutor` consumes loader attributes rather than a
changed method signature.

Obligation: the fix must not change public method signatures or the shape of
`migrated_apps`, `unmigrated_apps`, or `disk_migrations`.
