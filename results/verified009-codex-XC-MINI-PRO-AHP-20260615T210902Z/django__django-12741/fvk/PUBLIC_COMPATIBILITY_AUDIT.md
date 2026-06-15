# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol

`django.db.backends.base.operations.BaseDatabaseOperations.execute_sql_flush`

- Old source signature: `execute_sql_flush(self, using, sql_list)`
- Required/new source signature: `execute_sql_flush(self, sql_list)`
- Compatibility interpretation: intentionally incompatible with old direct calls because the public issue explicitly requests dropping `using`.

## In-repository definitions and overrides

Search evidence: `rg -n "def execute_sql_flush|execute_sql_flush\\(" repo/django repo/tests`

- Production definitions under `repo/django`: one definition, in `repo/django/db/backends/base/operations.py`.
- Backend overrides under `repo/django/db/backends`: none found.
- Result: no in-repository backend override remains with the old signature.

## In-repository production call sites

- `repo/django/core/management/commands/flush.py` calls `connection.ops.execute_sql_flush(sql_list)`.
- Result: production source caller is compatible with the new API.

## In-repository tests

- `repo/tests/backends/base/test_operations.py` still calls `connection.ops.execute_sql_flush(connection.alias, sql_list)`.
- `repo/tests/backends/tests.py` still calls `connection.ops.execute_sql_flush(connection.alias, sql_list)`.
- Status: suspect legacy tests for this issue. They encode the redundant argument the public issue says to remove. In normal project maintenance they should be updated to the new call shape, but this benchmark forbids modifying tests.

## External compatibility

Third-party database backends overriding `execute_sql_flush(self, using, sql_list)` are outside the allowed inputs and cannot be audited here. Because the issue explicitly asks to simplify the signature, this residual risk does not justify retaining a compatibility overload in the production fix.
