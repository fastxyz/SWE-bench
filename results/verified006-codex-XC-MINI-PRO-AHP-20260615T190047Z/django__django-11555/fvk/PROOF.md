# Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Claims Proved in the Constructed Model

The constructed K artifacts are:

- `fvk/mini-django-ordering.k`
- `fvk/django-ordering-spec.k`

They model the property-carrying fragment of Django ordering compilation:
ordering item kind, expression tree rewriting, `F()` leaf resolution relative
to `(opts, alias)`, `OrderBy` wrapping, descending reversal, and the string path
frame.

## Proof Sketch

1. Expression bypass: `find_ordering_name()` first checks
   `hasattr(name, 'resolve_expression')`. On that branch it returns an ordering
   pair before the later `get_order_dir(name, default_order)` statement. By
   reachability transitivity, expression inputs cannot reach the string-only
   subscript operation. This discharges PO1 and Finding F1.

2. Expression normalization: after expression resolution, the branch applies
   the same normalization shape used by top-level `get_order_by()`: cast
   `Value`, preserve existing `OrderBy`, wrap non-`OrderBy` with `.asc()`, and
   reverse a copied ordering expression when `default_order == 'DESC'`. This
   discharges PO2 and PO4.

3. Alias-relative `F()` leaves: `_resolve_ordering_expression()` performs
   structural induction over the finite expression tree. The base case for a
   plain `F(path)` calls `_setup_joins(path.split(LOOKUP_SEP), opts, alias)`,
   trims joins, and applies the returned `transform_function` to the target.
   This is the same field-resolution mechanism used by string ordering from a
   related model context, so the resulting column is relative to the current
   related `(opts, alias)`. This discharges PO3.

4. Recursive expression trees: for normal expression nodes, the helper copies
   the expression and recursively rewrites each non-`None` source expression.
   The induction measure is the finite number of source-expression nodes. This
   discharges the normal-expression part of PO6.

5. Non-source children: V2 adds a guard for objects without
   `get_source_expressions()`. Such nodes are returned unchanged, preventing the
   V1 helper from imposing `copy()`/source-expression requirements on objects
   such as `Q`. This discharges Finding F2 and the safety part of PO6.

6. String frame: if `name` is not an expression, control skips the new branch
   and reaches the preexisting string path. No string-path code was changed.
   This discharges PO5.

7. Compatibility: no public signature or return shape changed, and the new
   helper is private to `SQLCompiler`. This discharges PO7.

## Residual Risk

PO8 remains outside the constructed proof: V2 does not prove alias-relative
lookup-string handling inside conditional `Q` children of `Case/When`
expressions. The reported issue and hints exercise `OrderBy`, `F`, and
`Lower`-style expressions, which are covered. Full conditional-expression
coverage should be specified and tested separately before changing the query
resolution API further.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-django-ordering.k --backend haskell
kast --backend haskell fvk/django-ordering-spec.k
kprove fvk/django-ordering-spec.k
```

Expected machine-check result: `#Top` for the claims in
`fvk/django-ordering-spec.k`.

## Test Recommendations

Do not remove tests based on this constructed proof. Add or keep regression
tests for:

- parent or related `order_by('relation')` with related
  `Meta.ordering = (OrderBy(F('name')), )`;
- related `Meta.ordering = (Lower('name'), )`;
- descending relation ordering that reverses the related expression ordering;
- a conditional `Case/When(Q(...))` related ordering case if Django intends to
  support that full expression family.
