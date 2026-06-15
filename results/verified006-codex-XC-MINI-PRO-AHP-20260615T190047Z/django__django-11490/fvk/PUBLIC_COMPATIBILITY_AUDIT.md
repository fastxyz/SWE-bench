# Public Compatibility Audit

Status: no compatibility break found by static inspection.

## Changed symbol

`SQLCompiler.get_combinator_sql()` in
`repo/django/db/models/sql/compiler.py`.

## Public API surface

No public method signature changed. No queryset method signature changed.
`QuerySet.values()`, `QuerySet.values_list()`, `QuerySet.union()`,
`QuerySet.intersection()`, and `QuerySet.difference()` retain their existing
call shapes.

## Callers and overrides

The changed expression constructs child compilers from cloned child queries:

```py
query.clone().get_compiler(self.using, self.connection)
```

This does not add a new virtual-dispatch argument or alter a caller-visible
return type. It uses existing `Query.clone()` and `Query.get_compiler()`
contracts.

## Producer/consumer shape

The `compilers` list still contains compiler objects for non-empty child
queries. Downstream code still calls `compiler.get_order_by()` and
`compiler.as_sql()` on compiler objects. The difference is only that each
compiler owns a cloned child query.

## Verdict

Compatible. No additional production-code change is justified by this audit.
