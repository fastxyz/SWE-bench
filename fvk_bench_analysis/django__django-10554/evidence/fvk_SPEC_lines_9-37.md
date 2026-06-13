# Excerpt: results/.../fvk/SPEC.md (the root-cause-adjacent narrative)

The fvk arm's SPEC.md frames the ENTIRE spec target as `Query.clone()` deep-copying
`combined_queries` (the V1 hypothesis), and narrates the symptom mechanism via
`get_combinator_sql`/`set_values` — NOT via `get_order_by` (the true fix site).

## SPEC.md:9-15 — the spec target (V1 fix)
```
The V1 fix changes one function — `django/db/models/sql/query.py :: Query.clone()`
— to deep-copy `combined_queries`:

    if self.combined_queries:
        obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

## SPEC.md:30-38 — VERBATIM (the primer's flagged lead, tell #4)
The primer (fvk-primer.md:148) flagged "django-10554 SPEC.md:31-38" as a possible
site where the root cause is told as the thing being fixed. It is NOT: these lines
narrate the WRONG mechanism (operand sharing -> set_values reset) as "what V1 fixes".
They quote the real *symptom string* ("ORDER BY position N is not in select list")
but mislocate the *cause* in `get_combinator_sql`, never in `get_order_by`.

```
30  The mutation that makes independence matter is in
31  `SQLCompiler.get_combinator_sql()` (`compiler.py:430`): when a combinator query is
32  compiled with a `values()/values_list()` column list, it calls `set_values()` on each
33  combined query to reset its selected columns to the outer column list. If a combined
34  `Query` object is **shared** between the original union and a derived queryset, that
35  reset is visible to both, and the original later emits a reduced column list while its
36  combinator `ORDER BY` still references a (now out-of-range) column position ->
37  `ORDER BY position N is not in select list`.
```

## Why this is the wrong region
- True fix (oracle): `SQLCompiler.get_order_by()` at compiler.py:359 changes
  `else: raise DatabaseError('ORDER BY term does not match any column in the result set.')`
  into `else: if col_alias: raise ...; else: self.query.add_select_col(src); resolved.set_source_expressions([RawSQL('%d' % len(self.query.select))])`.
  Plus a new helper `Query.add_select_col` in query.py.
- The artifacts NEVER mention `get_order_by`, `add_select_col`, the
  `'ORDER BY term does not match...'` raise, or compiler.py:356/359.
- The cited region (compiler.py:428/430, get_combinator_sql/set_values) is *adjacent*
  but is not where the gold patch lives.
