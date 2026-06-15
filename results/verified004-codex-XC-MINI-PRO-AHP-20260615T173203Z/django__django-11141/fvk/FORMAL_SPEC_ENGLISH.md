# Formal Spec English

Status: constructed from public evidence; not machine-checked.

FE-001. For each installed app, if migrations are disabled by
`MIGRATION_MODULES[app_label] = None`, the loader records the app in
`unmigrated_apps` and discovers no migrations.

FE-002. For each installed app, if the migrations module cannot be imported and
the existing missing-module rules classify that absence as "no migrations", the
loader records the app in `unmigrated_apps` and discovers no migrations.

FE-003. For each installed app, if the migrations module imports successfully
but does not expose `__path__`, the loader records the app in
`unmigrated_apps` and discovers no migrations.

FE-004. For each installed app, if the migrations module imports successfully
and exposes `__path__`, the loader records the app in `migrated_apps`, whether
or not the module exposes `__file__`.

FE-005. For a path-backed migrations package, including an implicit namespace
package, the loader computes migration names by applying the existing
`pkgutil.iter_modules(module.__path__)` filter: include non-package entries
whose names do not start with `_` or `~`.

FE-006. For each included migration name, the loader imports
`module_name.migration_name`, requires a `Migration` class, and stores the
constructed migration under `(app_label, migration_name)` in `disk_migrations`.

FE-007. The namespace fix preserves public API shape: `load_disk()` still
returns through side effects on `disk_migrations`, `unmigrated_apps`, and
`migrated_apps`, and no method signatures change.
