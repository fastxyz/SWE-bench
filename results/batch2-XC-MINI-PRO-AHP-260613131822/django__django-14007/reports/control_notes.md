# Control notes: django__django-14007 (V2 review outcome)

## Decision summary

**V1 stands unchanged.** A systematic review (recorded in `review/FINDINGS.md`)
found no correctness defects, regressions, edge-case failures, or convention
violations. No source edits were made in this pass. Below, every decision —
including the decision *not* to change the code — is traced to numbered findings.

## The V1 change being reviewed

`SQLInsertCompiler.execute_sql()` (`repo/django/db/models/sql/compiler.py`)
captures the rows returned from the three retrieval branches
(`fetch_returned_insert_rows` / `fetch_returned_insert_columns` /
`last_insert_id`), then, using `Col` expressions built from
`self.returning_fields`, resolves converters via the inherited
`get_converters()` and applies them via `apply_converters()` before returning.

## Decisions and their justification

1. **Keep the core approach (route returned values through
   `get_converters`/`apply_converters`).** Justified by Findings #1, #2, #3: it
   fixes the reported bug, reuses the exact SELECT-path machinery, and preserves
   the same backend→field converter ordering, so `from_db_value` sees identical
   input on INSERT and SELECT. A narrower hand-rolled "call `from_db_value` only"
   approach was rejected because it would drop backend converters and diverge from
   the read path (Finding #3).

2. **Keep wrapping returning fields in `Col` via
   `field.get_col(opts.db_table)`.** Justified by Finding #4: backend
   `get_db_converters` implementations require `expression.output_field` (all) and
   `expression.field` (Oracle), which a bare `Field` lacks; `Col` supplies both.
   Considered passing raw fields and rejected — it would raise `AttributeError`
   on SQLite/MySQL/Oracle.

3. **Keep the `if converters:` guard and return `rows` unchanged when empty.**
   Justified by Findings #5 and #7: for all default auto fields on all four
   backends `get_converters` is empty, so the guard preserves the pre-V1 return
   object and shape exactly — zero regression for non-custom fields.

4. **Keep the `list(...)` materialization of the converted rows.** Justified by
   Finding #6: the consumer in `base.py` subscripts `results[0]` and tests
   `if results:`; `apply_converters` is a generator, so without `list()` these
   would break. This is load-bearing, not stylistic, so it was deliberately
   retained.

5. **Keep the `if/elif/else` restructure of the original early returns.**
   Justified by Finding #8: control flow and the inner `assert len(objs) == 1`
   are provably equivalent to the original, given the method's top-level assert.
   No behavioral change; needed so all branches share one conversion tail.

6. **Keep applying converters after the `with cursor` block, and keep the hoisted
   `opts`.** Justified by Finding #11: all fetch helpers eagerly materialize rows,
   so converting after the cursor closes is safe and releases the cursor sooner;
   `opts` is reused for both `last_insert_id` and `get_col`.

7. **Do not add defensive handling for "more returning fields than returned
   columns."** Justified by Finding #10: the only path with a fixed single value
   (`last_insert_id`) runs solely on non-RETURNING backends, where
   `db_returning_fields` is the single auto PK; RETURNING paths return exactly
   `len(returning_fields)` columns. Positions always align, so the hypothetical
   `IndexError` cannot occur and guard code would be dead.

8. **Do not special-case multi-table inheritance / proxy models / the `get_col`
   alias.** Justified by Finding #12: these Cols are never compiled to SQL, so the
   alias does not affect converter lookup; in practice each insert's returning
   field lives on `opts.db_table`. No change warranted.

9. **Accept the minor per-insert overhead of building cols/converters.**
   Justified by Finding #14: it is a handful of method calls per returning field,
   mirrors the SELECT path's existing cost, and rows are not copied when no
   converter applies.

10. **No changes to callers or other backends.** Justified by Finding #13: the
    insert `execute_sql` has a single caller and two reviewed result consumers;
    MySQL inherits the fix and no other backend/contrib overrides it. One edit
    fully covers the issue.

## Net result

The fix remains the single, minimal edit from V1. The review confirms it resolves
the issue described in `benchmark/PROBLEM.md` for `create()`, `save()`, and
`bulk_create()` across backends, while leaving behavior for ordinary fields
unchanged. `reports/baseline_notes.md` (V1 rationale) remains accurate; this
document records the audit that confirms it.
