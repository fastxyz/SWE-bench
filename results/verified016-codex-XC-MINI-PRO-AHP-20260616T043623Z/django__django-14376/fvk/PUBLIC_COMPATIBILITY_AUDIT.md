# Public Compatibility Audit

Status: no compatibility blocker found.

## Changed Public Surface

No method signature changed.

Changed observable dictionary keys generated from standard settings:

- `NAME`: `db` -> `database`
- `PASSWORD`: `passwd` -> `password`

This is the public issue's requested behavioral change and is compatible with
the mysqlclient versions supported by this Django checkout.

## Callers and Consumers

- `DatabaseWrapper.get_new_connection()` still calls
  `Database.connect(**conn_params)`.
- The version guard in `mysql/base.py` requires mysqlclient 1.4.0 or newer.
- The issue states mysqlclient supports `database` and `password` since 1.3.8.

## Overrides and Subclasses

No public override or virtual dispatch signature is changed. The fix changes
dictionary contents only.

## OPTIONS Compatibility

`OPTIONS` remains pass-through after `isolation_level` is removed. Canonical
`OPTIONS['database']` and `OPTIONS['password']` override standard settings.
Legacy user-provided aliases remain user-owned pass-through entries and are not
rewritten by this fix.
