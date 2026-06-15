# Proof Obligations

Status: constructed, not machine-checked.

PO1. Expression ordering items must be detected before `get_order_dir()`.

- Evidence: E1-E3.
- Code point: expression branch at the start of `find_ordering_name()`.
- Discharge condition: every `name` with `resolve_expression` returns from the
  expression branch and cannot reach the subsequent string indexing call.

PO2. Related non-`OrderBy` expressions must be normalized like top-level
ordering expressions.

- Evidence: E3, E5, E7.
- Code point: `Value` cast, `.asc()` wrapping, and `OrderBy` preservation in
  the expression branch.

PO3. Plain `F(path)` leaves must resolve from the related context.

- Evidence: E6, E8.
- Code point: `_resolve_ordering_expression()` calls `_setup_joins()` with the
  current `opts` and `alias`, then `trim_joins()` and `transform_function`.
- Discharge condition: `F('name')` in a related model expression denotes the
  related model's `name` column, not the root query model's `name` column.

PO4. Enclosing descending relation ordering must reverse expression ordering.

- Evidence: E5 and existing string-ordering semantics.
- Code point: `if default_order == 'DESC': copy(); reverse_ordering()`.
- Discharge condition: `order_by('-relation')` flips the related model's
  expression ordering just as it flips string ordering.

PO5. String ordering behavior must remain framed.

- Evidence: I5.
- Code point: the existing `get_order_dir()` string path is reached only for
  non-expression items and is otherwise unchanged.

PO6. Expression tree rewriting must not assume every child is a normal
`BaseExpression`.

- Evidence: E9.
- Code point: V2 guard `if not hasattr(expr, 'get_source_expressions'): return expr`.
- Discharge condition: non-source child nodes are preserved instead of causing
  helper-level `AttributeError`.

PO7. Public compatibility must be preserved.

- Evidence: I6.
- Code point: no signature change to `find_ordering_name()`; new helper is
  private; return shape unchanged.

PO8. Residual boundary: conditional `Q` lookup strings inside related ordering
expressions are not proved alias-relative.

- Evidence: expression API supports conditional expressions, but the public
  issue and hints identify `OrderBy` and `Lower` failures.
- Status: not a blocker for this issue fix; recommended follow-up test/spec
  if Django wants full related-context semantics for `Case/When(Q(...))` in
  `Meta.ordering`.
