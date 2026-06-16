# Public Evidence Ledger

| ID | Source | Quoted evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "MySQL backend uses deprecated 'db' and 'passwd' kwargs." | Remove Django-generated use of these kwargs. |
| E2 | `benchmark/PROBLEM.md` | "in favor of 'database' and 'password' respectively" | Use `database` for database name and `password` for password. |
| E3 | `benchmark/PROBLEM.md` | "mysqlclient added support for 'database' and 'password' in 1.3.8" | The replacement kwargs are valid for supported versions. |
| E4 | `benchmark/PROBLEM.md` | "Django ... require a minimum version of mysqlclient newer than 1.3.8" | No old-version fallback is necessary. |
| E5 | `repo/docs/ref/databases.txt` | "Connection settings are used in this order: OPTIONS, NAME, USER, PASSWORD, HOST, PORT, MySQL option files." | Preserve canonical `OPTIONS` precedence. |
| E6 | `repo/docs/ref/databases.txt` | "Several other MySQLdb connection options may be useful" | Preserve pass-through behavior for arbitrary `OPTIONS`. |
| E7 | `repo/django/db/backends/mysql/base.py` | Surrounding code sets `user`, `host`/`unix_socket`, `port`, `client_flag`, validates `isolation_level`, then merges `OPTIONS`. | Frame unrelated behavior. |
