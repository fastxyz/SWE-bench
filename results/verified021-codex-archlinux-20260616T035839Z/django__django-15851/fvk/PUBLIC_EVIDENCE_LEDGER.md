# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| IE-01 | prompt | "dbshell additional parameters should be passed before dbname on PostgreSQL." | Ordering: `parameters` precedes positional dbname. | Encoded in C-DBNAME and C-DEFAULT-POSTGRES. |
| IE-02 | prompt | "`psql` expects all options to proceed the database name, if provided." | PostgreSQL options after dbname are invalid for the reported workflow. | Encoded in C-DBNAME. |
| IE-03 | prompt | `-c "select * from some_table;"` is reported ignored as an extra command-line argument. | Concrete counterexample for legacy ordering. | Finding F-01. |
| IE-04 | prompt | "leaving the database name for the end of the args list." | If there is a positional database argument, it is last. | Encoded in C-DBNAME and C-DEFAULT-POSTGRES. |
| IE-05 | source | `dbshell.py` collects `parameters` and calls `connection.client.runshell(options["parameters"])`. | The backend client is responsible for final command ordering. | Proof obligation PO-06. |
| IE-06 | source | `BaseDatabaseClient.runshell()` runs the `args` returned by `settings_to_cmd_args_env()`. | The returned `args` list is the observable relevant to this issue. | Proof obligation PO-06. |
| IE-07 | public-test | `test_postgresql.py::test_parameters` expects `["psql", "dbname", "--help"]`. | This conflicts with IE-01/IE-04 and encodes the legacy bug pattern. | SUSPECT; Finding F-02. |
| IE-08 | source | PostgreSQL client populates `PGPASSWORD`, `PGSERVICE`, `PGSSLMODE`, `PGSSLROOTCERT`, `PGSSLCERT`, `PGSSLKEY`, and `PGPASSFILE` after building args. | Environment result is a frame condition. | Proof obligation PO-04. |
| IE-09 | source/public-test | Service configuration returns `["psql"]` with `PGSERVICE`, without appending dbname. | V1 must not introduce a positional dbname for service-only configs. | Encoded in C-SERVICE-NO-DBNAME. |
