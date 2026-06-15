# Public Compatibility Audit

## Changed symbol

- `django.db.backends.postgresql.client.DatabaseClient.runshell_db(cls, conn_params)`

## Signature compatibility

Status: pass. The method remains a classmethod taking the same `conn_params` argument. No caller
changes are required.

## Callsite compatibility

Status: pass. `runshell()` still calls:

```python
DatabaseClient.runshell_db(self.connection.get_connection_params())
```

`get_connection_params()` already includes PostgreSQL `OPTIONS`, so SSL values reach
`runshell_db()` without changing the caller or the settings schema.

## Observable subprocess compatibility

Status: pass. Existing `psql` arguments and `PGPASSWORD` behavior are preserved. V1 only adds
extra environment variables when corresponding SSL connection parameters are present.

## Subclass / override compatibility

No in-repository PostgreSQL subclass override of `runshell_db()` was identified in the audited
source path. The public method signature was not changed.
