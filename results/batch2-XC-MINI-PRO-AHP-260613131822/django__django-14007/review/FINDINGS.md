# Code review findings: django__django-14007 (V1 fix)

Scope: `SQLInsertCompiler.execute_sql()` in
`repo/django/db/models/sql/compiler.py` (lines 1403–1430), the only edit in V1.

Legend: **[OK]** verified correct/no action; **[NOTE]** worth recording, no
change required; **[RISK]** potential problem evaluated.

---

## 1. Correctness against the issue — [OK]
The issue: `from_db_value` (and other DB converters) are not applied to the
values returned for `returning_fields` after an INSERT, so a custom
`BigAutoField` subclass returns a bare `int` from `create()`/`bulk_create()`
instead of its wrapper type. V1 builds `Col` expressions from
`self.returning_fields`, resolves converters with the inherited
`self.get_converters(cols)`, and runs the fetched rows through
`self.apply_converters(rows, converters)` before returning. `Col.get_db_converters`
delegates to `output_field.get_db_converters`, which returns `[self.from_db_value]`
when defined (`fields/__init__.py:746`). So the hook is now invoked for the
returned PK on every insert path. The reported scenario is fixed.

## 2. Reuse of the exact SELECT-path machinery — [OK]
`results_iter` (compiler.py:1121) resolves converters with `get_converters` and
applies them with `apply_converters`. V1 calls the identical inherited helpers,
so INSERT conversion is by construction consistent with SELECT: same converter
list, same `(value, expression, connection)` call signature.

## 3. Converter ordering matches SELECT — [OK]
`get_converters` composes `backend_converters + field_converters` (compiler.py:1107).
Thus backend converters run *before* `from_db_value`, exactly as on reads. A
custom `from_db_value` therefore receives the same input on INSERT as on SELECT;
no risk of it seeing a differently-typed value depending on code path.

## 4. `Col` is required instead of the raw `Field` — [OK]
`connection.ops.get_db_converters(expression)` inspects `expression.output_field`
(SQLite/MySQL/Oracle backends) and, on Oracle, also `expression.field`
(operations.py:199, `empty_strings_allowed`). A bare `Field` has neither
attribute, so passing fields directly would raise `AttributeError` on those
backends. `field.get_col(opts.db_table)` yields a `Col` whose `output_field`/
`field`/`target` all resolve to the field (`expressions.py:817`, `field` property
at `expressions.py:259`). Verified `Col` satisfies every backend's
`get_db_converters` contract.

## 5. No regression for default auto fields — [OK]
For a plain `AutoField`/`BigAutoField`/`SmallAutoField` (the only fields with
`db_returning=True`, `fields/__init__.py:2451`):
- SQLite: `get_db_converters` matches only DateTime/Date/Time/Decimal/UUID/Boolean
  internal types — none match an auto field; field has no `from_db_value`.
- PostgreSQL: base `get_db_converters` returns `[]`.
- MySQL: matches only Boolean/DateTime/UUID — no match.
- Oracle: matches none of its internal-type branches; `empty_strings_allowed` is
  `False` for integer auto fields, so `convert_empty_string` is not appended.
In all four, `get_converters` returns an empty dict, `if converters:` is False,
and `rows` is returned unchanged (same object/shape as before V1). Existing
behavior for non-custom fields is byte-for-byte preserved.

## 6. `list()` materialization is necessary — [OK]
`apply_converters` is a generator. The consumer in `base.py:874` does
`results[0]` (subscripting) and `if results:` truthiness, and
`_batched_insert` does `inserted_rows.extend(...)`. A generator would make
`results[0]` raise `TypeError` and `if results:` always truthy. V1 wraps the
conversion in `list(...)`, so the return value stays a concrete, indexable list.
Confirmed essential, not cosmetic.

## 7. Row shape (list vs tuple) is irrelevant to consumers — [OK]
When converters apply, rows become lists; otherwise they keep their fetched shape
(list of tuples). Both consumers (`base.py:874`, `query.py:506/520`) only iterate
positionally via `zip(...)`. No caller depends on tuple identity, hashing, or
pickling of these rows. No observable change.

## 8. `if/elif/else` is equivalent to the original early returns — [OK]
The original used `return` in each branch; the top-level assert guarantees that
multiple-object inserts with `returning_fields` only occur when
`can_return_rows_from_bulk_insert` is True. Hence: branch 1 (bulk) ⇔ first
condition; branch 2 requires `len(objs) == 1` (its assert preserved); branch 3
(last_insert_id) is the single-row fallback. Rewriting the early returns as a
shared `rows` assignment with `elif/else` preserves identical control flow and
the inner asserts.

## 9. Truthiness guard in `get_converters` — [OK]
`get_converters` skips falsy expressions (`if expression:`). `Col`/`Expression`
define no `__bool__` or `__len__` (grep confirmed none in `expressions.py`), so a
constructed `Col` is always truthy and is never skipped. This is the same guard
the SELECT path relies on for its Cols.

## 10. Multiple returning fields / index alignment — [OK / RISK-evaluated]
For RETURNING paths, the DB returns exactly `len(returning_fields)` columns and
`cols` has the same length, so converter positions align with row positions —
no `IndexError`. The `last_insert_id` fallback returns a single value `[(pk,)]`,
but that path only runs for backends without RETURNING, where a model's
`db_returning_fields` is just the single auto PK (the docstring at
`fields/__init__.py:760` notes multi-field returning is PostgreSQL-only, which
uses RETURNING). Therefore `returning_fields` length and row length always match;
the theoretical `IndexError` cannot occur. No defensive code needed.

## 11. Cursor lifecycle — [OK]
V1 fetches all rows inside the `with self.connection.cursor()` block
(`fetch_returned_insert_rows`/`fetch_returned_insert_columns`/`last_insert_id` all
eagerly materialize), then applies converters *after* the cursor closes.
Converters never touch the cursor, so converting post-close is safe and slightly
better (cursor released sooner). `opts = self.query.get_meta()` is hoisted above
the block and reused for both `last_insert_id` and `get_col`.

## 12. Multi-table inheritance / proxy models / alias choice — [OK]
The `alias` given to `get_col` only affects SQL generation; these Cols are never
compiled to SQL (used solely for converter lookup), so the alias is immaterial to
correctness. In practice MTI performs one insert per table whose
`returning_fields` is that table's own auto PK (so `field.model._meta.db_table ==
opts.db_table` and `cached_col` is returned); proxy models share the parent
table. Even a mismatched alias would still produce a valid `Col` with the correct
`output_field`. No issue.

## 13. Blast radius / other callers and overrides — [OK]
The insert `execute_sql(returning_fields)` has a single caller,
`QuerySet._insert` (`query.py:1289`); its results flow only to
`Model._save_table` and `QuerySet._batched_insert`, both reviewed above. The
MySQL `SQLInsertCompiler` is `pass` (inherits the fix); no PostgreSQL/Oracle/
contrib/GIS override of the insert `execute_sql` exists (grep confirmed). One
edit therefore covers all backends with no other code paths affected.

## 14. Performance — [NOTE]
Every insert now builds `cols` and calls `get_converters` (a few method calls per
returning field, typically one). When there are no converters the rows are not
copied. This mirrors the per-query cost already paid on the SELECT path and is
negligible. Acceptable; no change.

---

## Conclusion
No correctness, regression, edge-case, or convention problems were found. The V1
fix is minimal, mirrors the established SELECT converter machinery, is compatible
with every backend's `get_db_converters` contract, and preserves existing
behavior exactly for non-custom fields. V1 stands unchanged.
