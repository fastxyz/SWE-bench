# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Simplify signature of `DatabaseOperations.execute_sql_flush()`" | The method signature is part of the required change. | Encoded in I1 and the K arity model. |
| E2 | `benchmark/PROBLEM.md` | "`def execute_sql_flush(self, using, sql_list):`" followed by "`def execute_sql_flush(self, sql_list):`" | Drop the `using` parameter rather than retaining a compatibility overload. | Encoded in I1; old arity marked suspect. |
| E3 | `benchmark/PROBLEM.md` | "The using argument can be dropped and inferred by the calling instance: `self.connection.alias`." | The transaction alias used inside the method must be `self.connection.alias`. | Encoded in I2 and PO2. |
| E4 | `benchmark/PROBLEM.md` | "Some internal uses of this method are already doing: `connection.ops.execute_sql_flush(connection.alias, sql_flush)`" | Internal callers should no longer pass `connection.alias` because it is redundant with the bound connection. | Encoded in I4 and compatibility audit. |
| E5 | `repo/django/db/backends/base/operations.py` | `BaseDatabaseOperations.__init__(self, connection)` stores `self.connection = connection`. | The operations instance has access to its bound connection. | Supports D1 and PO2. |
| E6 | `repo/django/db/backends/base/base.py` | `self.alias = alias` and `self.ops = self.ops_class(self)`. | The bound connection has the alias the operation should infer. | Supports D2 and PO2. |
| E7 | `repo/django/db/backends/base/operations.py` | Existing method body used `transaction.atomic(...); with self.connection.cursor() as cursor; for sql in sql_list: cursor.execute(sql)`. | Preserve transaction/cursor/list execution semantics while changing the redundant alias source. | Encoded in I3, PO3. |
| E8 | `repo/django/core/management/commands/flush.py` | `database = options['database']`; `connection = connections[database]`; V1 calls `connection.ops.execute_sql_flush(sql_list)`. | The command caller resolves the connection first and should call the simplified API. | Encoded in I4, PO4. |
| E9 | `repo/tests/backends/base/test_operations.py` and `repo/tests/backends/tests.py` | Visible tests still call `connection.ops.execute_sql_flush(connection.alias, sql_list)`. | Suspect legacy evidence, because it conflicts with E1-E4. It suggests tests should be updated in normal development, but benchmark rules forbid editing tests. | Finding F2, not a source-code blocker. |
