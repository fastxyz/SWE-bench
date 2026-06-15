# Formal Spec, In English

The K model uses `deleteShape(activeAliases, extraTables)`.

- `activeAliases` is the number of aliases in `query.alias_map` whose refcount is greater than zero before the delete branch decision.
- If `activeAliases == 0`, the compiler first initializes the base table alias, so the normalized active-alias count becomes `1`.
- `extraTables` is the number of explicit `query.extra_tables` contributors.
- `deleteShape(...) == direct` means `SQLDeleteCompiler.as_sql()` takes `_as_sql(self.query)`, emitting direct `DELETE FROM base_table ...`.
- `deleteShape(...) == fallback` means `SQLDeleteCompiler.as_sql()` does not take the direct branch; the default backend uses the primary-key subquery fallback, while the MySQL subclass may use its multi-table delete fallback when self-select is unavailable.

Claims:

1. `deleteShape(0, 0) == direct`. An unfiltered fast delete with no aliases initialized is normalized to one base alias and directly deleted.
2. `deleteShape(1, 0) == direct`. A query already known to have one active alias and no extra tables remains a direct delete.
3. For every `activeAliases >= 2`, `deleteShape(activeAliases, 0) == fallback`. A multi-alias query is not represented as a simple direct delete.
4. For every `activeAliases >= 0` and `extraTables > 0`, `deleteShape(activeAliases, extraTables) == fallback`. Explicit extra tables are not represented as a simple direct delete.

No loop, recursion, mutation beyond alias normalization, ordering, or termination property is in scope for this unit.
