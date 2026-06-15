# Public Compatibility Audit

Status: constructed audit from source inspection.

Changed symbol: `Query.check_filterable(self, expression)`.

Signature change: none.

Callers inspected:

- `build_filter()` calls `check_filterable()` on `reffed_expression` and on the
  resolved RHS value.
- `_add_q()` passes the `check_filterable` flag through to `build_filter()`.
- `Q.resolve_expression()` can disable this check for Q-as-expression handling,
  unchanged by V2.

Compatibility result:

- Annotation and expression paths still expose `resolve_expression` and continue
  through the internal expression filterability checks.
- Ordinary RHS values without `resolve_expression` are no longer inspected as
  expression metadata, which is the intended compatibility restoration.
- No public method signatures, return types, dispatch shapes, or test files were
  changed.
