# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Scalar reproducer does not fail

For any merge attrs list with one entry from `cond`, `keep_attrs=True` and scalar `x` must return an attrs mapping without reading a missing index.

Evidence: E1, E2, E5.

Discharge: `x_attrs == []` for scalar `x`; V1's nested loops have no `x_attrs_` element to inspect and return `{}`.

## PO2 - Scalar `x` means empty preserved attrs

For scalar `x`, the selected attrs are `{}` regardless of attrs contributed by `cond` or `y`.

Evidence: E4, E5, E6.

Discharge: scalar `x` has no collected attrs sources, so the callable returns `{}` for all merge attrs lists.

## PO3 - X attrs are preserved when x contributes attrs

If a merge attrs list contains attrs content from `x`, the callable returns attrs with that same content.

Evidence: E4.

Discharge: V1 compares each current merge attrs dictionary with the collected attrs sources from `x` by identity or non-empty dictionary equivalence, and returns the matching current attrs dictionary.

## PO4 - No x source means no fallback source

If the current merge attrs list has no attrs content from `x`, the callable returns `{}`.

Evidence: E4, E6.

Discharge: the nested search finds no identity or non-empty equivalence match and reaches `return {}`.

## PO5 - Non-target behavior is framed

Non-`True` `keep_attrs` modes, public function signature, alignment options, dask option, and `apply_ufunc` call shape are unchanged.

Evidence: E7 and source diff.

Discharge: V1 edits only the body of `if keep_attrs is True`; the `apply_ufunc` arguments remain unchanged.

## PO6 - Honesty gate

The proof must be labeled constructed, not machine-checked, and tests must not be deleted or claimed redundant without a future successful `kprove` run.

Evidence: FVK verify guidance and task no-execution constraint.

Discharge: all FVK artifacts and reports include the no-execution caveat.
