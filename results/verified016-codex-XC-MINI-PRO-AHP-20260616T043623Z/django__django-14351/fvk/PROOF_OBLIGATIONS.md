# Proof Obligations

Status: constructed, not machine-checked.

PO-001 Intent adequacy. The formal claims must express the issue's intended
observable: a non-correlated related `__in` RHS queryset must not appear as a
multi-column subquery in the outer `GROUP BY`.

Status: discharged by `SPEC.md` C-001 and E-001/E-003/E-005.

PO-002 Non-correlated raw Query grouping. For `alias is None` and
`get_external_cols() == []`, `Query.get_group_by_cols()` must return `[]`.

Status: discharged by source:

```python
external_cols = self.get_external_cols()
if any(col.possibly_multivalued for col in external_cols):
    return [self]
return external_cols
```

With `external_cols == []`, `any(...)` is false and the returned value is `[]`.
This is also claim C-001 in `fvk/query-group-by-spec.k`.

PO-003 Scalar correlated raw Query grouping. For `alias is None`,
`get_external_cols() == external_cols`, and no external column is possibly
multivalued, `Query.get_group_by_cols()` must return `external_cols`.

Status: discharged by the same source branch and claim C-002.

PO-004 Possibly-multivalued correlated fallback. For `alias is None` and any
external column marked possibly multivalued, `Query.get_group_by_cols()` must
return `[self]`, preserving the existing conservative `Subquery` behavior.

Status: discharged by the `if any(...)` branch and claim C-003.

PO-005 Explicit alias preservation. For a truthy `alias`,
`Query.get_group_by_cols(alias)` must return `[Ref(alias, self)]`.

Status: discharged by the first branch of V1 and claim C-004.

PO-006 Frame condition. The method must not mutate `Query`, `external_aliases`,
`where`, `annotations`, or select state while collecting group-by dependencies.

Status: discharged by source inspection. V1 only reads `self.get_external_cols()`
and constructs a return list; it does not call mutating methods such as
`clear_select_clause()`, `add_fields()`, or `set_select()`.

PO-007 Integration with HAVING group-by collection. In the reported shape,
`Lookup.get_group_by_cols()` returns LHS columns plus RHS group-by columns.
Therefore, after PO-002, the RHS contributes no raw query expression and the
outer `GROUP BY` cannot compile the default-column RHS subquery.

Status: discharged by source inspection:

```python
cols = self.lhs.get_group_by_cols()
if hasattr(self.rhs, 'get_group_by_cols'):
    cols.extend(self.rhs.get_group_by_cols())
return cols
```

For the reported non-correlated RHS, PO-002 makes the extension empty.

PO-008 Honesty gate. The proof must be labeled constructed, not
machine-checked, because this task forbids running K tooling.

Status: discharged by all FVK artifacts and by recording commands without
execution.
