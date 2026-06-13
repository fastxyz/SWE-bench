# V1 (solution_baseline.patch) vs final (solution_fvk.patch)

`diff solution_baseline.patch solution_fvk.patch` -> they differ ONLY cosmetically.
Both add the SAME block to `django/db/models/sql/query.py :: Query.clone()`
(deep-copy combined_queries). fvk's only substantive change: swap the guard token
`if self.combinator:` (V1) -> `if self.combined_queries:` (fvk), plus reworded comment.
The cloned line is byte-identical. Behavior-identical (combinator <=> combined_queries).
=> fvk CONFIRMED V1; it did not relocate or rethink the fix.

Both patches touch ONLY Query.clone(). NEITHER touches get_order_by / add_select_col
(the oracle fix site).

## diff output
```
2c2
< index 08d7faf194..597ee6c2c9 100644
---
> index 08d7faf194..9238bc3f2d 100644
9,14c9,15
< +        # Combined queries are mutated in place when set operations are
< +        # compiled (e.g. by set_values()), so they must not be shared between
< +        # a query and its clones. Otherwise, evaluating a derived queryset
< +        # (e.g. via values_list()) would leak its column/ordering changes into
< +        # the original combined queryset and break its re-evaluation.
< +        if self.combinator:
---
> +        # Combined queries (the operands of union()/intersection()/difference())
> +        # get their selected columns reset to the outer query's column list
> +        # while the set operation is compiled, so they must not be shared
> +        # between a query and its clones. Otherwise evaluating a queryset
> +        # derived from a set operation (e.g. via values_list()) corrupts the
> +        # original's combined queries and breaks its later re-evaluation.
> +        if self.combined_queries:
```
