# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO-1: Built-in list constructor preservation

For any top-level built-in list input `L = [v0, ..., vn]`,
`resolve_lookup_value(L, can_reuse, allow_joins, simple_col)` returns a list,
not a tuple. Its elements are the resolved versions of `v0, ..., vn`.

Evidence: E1, E3, E4.

Discharge: V1 returns `resolved_values` for non-tuple inputs in the list/tuple
branch. In that branch, `resolved_values` is a Python list.

Status: discharged by V1.

## PO-2: Tuple constructor preservation

For any top-level tuple input `T = (v0, ..., vn)`,
`resolve_lookup_value(T, can_reuse, allow_joins, simple_col)` returns a tuple.
Its elements are the resolved versions of `v0, ..., vn`.

Evidence: E4 and existing method scope.

Discharge: V1 returns `tuple(resolved_values)` when the original `value` is a
tuple.

Status: discharged by V1.

## PO-3: Element-wise expression resolution is preserved

For each element of a top-level list or tuple:

- If the element has `resolve_expression()` and is an `F` expression, resolve it
  with `reuse`, `allow_joins`, and `simple_col`.
- If the element has `resolve_expression()` and is not an `F` expression,
  resolve it with `reuse` and `allow_joins`.
- Otherwise, keep the element unchanged.

Evidence: E5 and source behavior outside the reported bug.

Discharge: V1 did not change the loop body that resolves or appends elements.

Status: discharged by V1.

## PO-4: Non-iterable and top-level expression frame behavior

Top-level values with `resolve_expression()` still use the existing expression
path. Values without `resolve_expression()` that are not list or tuple values
are returned unchanged.

Evidence: source frame behavior and absence of prompt evidence to change it.

Discharge: V1 changes only the reconstruction after the list/tuple branch.

Status: discharged by V1.

## PO-5: Exact lookup integration

The type-preserved right-hand side returned by `resolve_lookup_value()` must be
the value passed into lookup construction and field preparation for exact
lookups.

Evidence: E2, E3, E6.

Discharge: `build_filter()` assigns
`value = self.resolve_lookup_value(...)` and passes `value` into
`self.build_lookup(...)`. The exact lookup path calls field preparation from
that lookup RHS. No later top-level tuple conversion was found on this path.

Status: discharged by source inspection.

## PO-6: Public compatibility

The fix must not change the method signature, dispatch shape, or unrelated
lookup behavior.

Evidence: E7.

Discharge: V1 changes only the branch's final reconstruction expression.
No call sites require a signature update, and no overrides were found.

Status: discharged by source inspection.

## PO-7: Exact subclass behavior

Potential obligation:

For subclasses of `list` or `tuple`, should the exact concrete subclass be
preserved after element resolution?

Evidence:

Only E4 could support this, and it is ambiguous because the issue specifically
describes "value of type list" while the method's explicit supported categories
are list and tuple.

Discharge:

Not discharged and not included in the proven contract. This is a residual
ambiguity, not a V1 failure against the public issue.

Status: unresolved/under-specified, recorded as F-003.

