# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: none.

Changed internal symbol:

- `django.db.models.sql.compiler.SQLDeleteCompiler.single_alias`

Compatibility checks:

| Surface | Audit | Result |
| --- | --- | --- |
| Method signature | `single_alias` remains a zero-argument cached property. No caller changes are required. | Pass |
| Return type | Still returns `bool`. | Pass |
| Base compiler caller | `SQLDeleteCompiler.as_sql()` still branches on truthiness of `self.single_alias`. | Pass |
| MySQL subclass caller | `django/db/backends/mysql/compiler.py` still branches on `self.single_alias` and delegates to `super().as_sql()` for direct/safe cases. | Pass |
| Test files | No test files are modified. | Pass |

The only behavioral compatibility change is intentional: an uninitialized single-table delete now counts the base alias before the branch decision, and `extra_tables` prevents the direct branch.
