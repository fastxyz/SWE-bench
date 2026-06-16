# Public Compatibility Audit

Status: constructed for FVK, not machine-checked.

## Changed Symbols and Observable Surfaces

`django.db.backends.sqlite3.base.check_sqlite_version`

- Signature: unchanged.
- Callers: source search found only the definition and the import-time call in
  `django/db/backends/sqlite3/base.py`.
- Behavior change: SQLite versions `< 3.9.0` now raise `ImproperlyConfigured`.
  This is intentional and required by the public issue.
- Compatibility status: pass.

`django/db/backends/sqlite3/introspection.py` comment

- Runtime behavior: unchanged.
- Compatibility status: pass.

`docs/ref/databases.txt`

- Public docs now state SQLite 3.9.0 or later.
- Compatibility status: pass.

`docs/ref/contrib/gis/install/index.txt`

- Public GeoDjango install table now states SQLite 3.9.0+.
- Compatibility status: pass.

## Overrides and Virtual Dispatch

No changed method signature, virtual dispatch call shape, return shape, storage
format, or subclass override obligation was found.
