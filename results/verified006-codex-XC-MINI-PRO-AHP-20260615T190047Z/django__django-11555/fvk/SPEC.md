# Specification

Status: FVK constructed, not machine-checked. This specification audits
`SQLCompiler.find_ordering_name()` and the new helper
`_resolve_ordering_expression()` in `repo/django/db/models/sql/compiler.py`.

## Public Intent Ledger

The public evidence ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.
Critical obligations are:

- `E1-E3`: related model default ordering must handle `Meta.ordering`
  expression items and must not pass them to `get_order_dir()`.
- `E4-E7`: Django already treats expression ordering as valid public behavior,
  including `F()`, `OrderBy`, and transform/function expressions such as
  `Lower()`/`Upper()`.
- `E8`: related model ordering must resolve field references from the related
  model alias and options, matching the string-ordering path.
- `E9`: non-expression child nodes inside expression trees must not be assumed
  to implement the `BaseExpression` copy/source protocol.

## Contract

For every call to `find_ordering_name(name, opts, alias, default_order,
already_seen)` in the verified domain:

1. If `name` has `resolve_expression`, `find_ordering_name()` must take the
   expression branch before `get_order_dir()` and return a one-element ordering
   list `(OrderBy(resolved_expression, direction), False)`.
2. If the expression item is a `Value`, it must be cast with its output field,
   preserving the top-level `get_order_by()` behavior.
3. If the expression item is not already `OrderBy`, it must be wrapped with
   `.asc()`.
4. If `default_order == 'DESC'`, the resulting ordering expression must be
   copied and reversed with `reverse_ordering()`.
5. Plain `F(path)` leaves inside the expression tree must resolve through
   `_setup_joins(path.split(LOOKUP_SEP), opts, alias)`, `trim_joins()`, and the
   returned `transform_function`, so field references are interpreted relative
   to the current related model alias.
6. Expression subtrees that expose the normal source-expression protocol must
   be copied and recursively rewritten; non-expression child nodes are left
   unchanged for their own resolver.
7. If `name` is not an expression, existing string behavior remains unchanged.

## Domain and Boundaries

The proof covers the reported issue family: `OrderBy(F(...))`, `F(...).asc()`,
`F(...).desc()`, and transform/function expressions such as `Lower('field')`
whose string arguments become plain `F()` leaves. It also covers finite nested
expression trees built from the standard source-expression protocol.

The proof does not claim full alias-relative handling for conditional
`Case/When(Q(...))` lookup strings inside related model `Meta.ordering`.
Those child nodes are no longer copied blindly after V2, but their lookup
strings are still resolved by their own resolver. This is tracked as residual
risk in `fvk/FINDINGS.md`.
