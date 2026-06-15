# Formal Spec in English

Status: paraphrase of `fvk/django-ordering-spec.k`; constructed, not
machine-checked.

## CLAIM-EXPRESSION-BYPASSES-GET-ORDER-DIR

For any ordering item marked as an expression, `find_ordering_name()` reaches
the expression ordering result directly. It does not evaluate the string-only
`get_order_dir()` operation.

## CLAIM-F-LEAF-USES-RELATED-CONTEXT

For any plain `F(path)` leaf in an expression ordering item, resolving that
leaf in context `(opts, alias)` yields the same column expression that the
existing string-ordering path would obtain by calling `_setup_joins()` and
`trim_joins()` from that `opts` and `alias`.

## CLAIM-NON-ORDERBY-ASC-WRAP

For any non-`OrderBy` expression item, the result is wrapped in ascending
`OrderBy` before it is returned.

## CLAIM-DESC-REVERSAL

For any expression ordering item expanded under `default_order == 'DESC'`, the
compiler returns a copied ordering expression whose direction and null-ordering
flags have been reversed by `reverse_ordering()`.

## CLAIM-STRING-FRAME

For any non-expression ordering item, the new expression branch is not taken
and the preexisting string-ordering transition remains the operative behavior.

## CLAIM-NON-SOURCE-CHILD-FRAME

For expression child nodes that do not expose `get_source_expressions()`, the
helper leaves the child node unchanged instead of assuming it can be copied as a
normal expression tree.
