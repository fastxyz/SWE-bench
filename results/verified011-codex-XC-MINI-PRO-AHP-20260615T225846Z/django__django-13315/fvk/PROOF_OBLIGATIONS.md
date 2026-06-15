# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-1 - Membership Equivalence

For any standard ForeignKey formfield outer queryset `B` and non-empty
`limit_choices_to` relation `L`, the patched queryset contains a row `r` from
`B` if and only if `witnesses(L, r) > 0`.

Formal shape:

```
r in patched(B, L) <=> r in B and exists witness . L(r, witness)
```

Discharge status: satisfied by V1. The code constructs
`Exists(base_manager.filter(L & Q(pk=OuterRef('pk'))))`, which is true exactly
when a row with the outer primary key satisfies `L`.

Related findings: F1, F4.

## PO-2 - No Duplicate Rows Introduced by Limit Join

If the outer queryset `B` has at most one row for each primary key, then
`patched(B, L)` has at most one row for each primary key, regardless of how many
join witnesses satisfy `L`.

Formal shape:

```
unique_pks(B) => unique_pks(patched(B, L))
```

Discharge status: satisfied by V1. The outer queryset is filtered in place by a
boolean `EXISTS` predicate. It is not joined to the witness relation, so one
outer row can either remain once or be excluded once.

Related findings: F1, F4.

## PO-3 - Validation Cannot See Limit-Induced Multiplicity

For any primary key `p` selected from `patched(B, L)`, filtering the same
queryset by `pk=p` has cardinality one when `unique_pks(B)` holds.

Formal shape:

```
unique_pks(B) and p in pks(patched(B, L))
  => count(row in patched(B, L) where row.pk = p) = 1
```

Discharge status: satisfied by V1. `ModelChoiceField.to_python()` uses the same
`field.queryset` that the helper rewrote, so the `.get(pk=p)` path is protected
by PO-2.

Related findings: F2.

## PO-4 - No Row-Wide DISTINCT Dependency

The repair must not rely on `.distinct()` or a row-wide `GROUP BY`/comparison of
all selected model columns.

Formal shape:

```
patched_query_operator = outer_filter(Exists(...))
patched_query_operator != row_wide_distinct(direct_join_filter(...))
```

Discharge status: satisfied by inspection of V1. The only new queryset operation
is `.filter(Exists(...))`; `.distinct()` is not introduced.

Related findings: F3.

## PO-5 - Limit Input Form Preservation

The helper must preserve accepted resolved limit forms:

- `Q` objects remain valid.
- dictionaries remain valid by conversion to `Q(**dict)`.
- empty limits are no-op.
- callable resolution remains delegated to `get_limit_choices_to()`.

Discharge status: satisfied by V1. The code calls `get_limit_choices_to()` as
before, branches only on a non-empty resolved value, converts non-`Q` values to
`Q(**limit_choices_to)`, and leaves falsey/empty limits unchanged.

Related findings: F1, F3.

## PO-6 - Public Compatibility and Honesty Gate

The fix must keep the helper signature and consumer protocol unchanged, and the
FVK proof must not be reported as machine-checked.

Discharge status: satisfied. V1 changes only the helper body and still assigns a
queryset to `formfield.queryset`. The FVK artifacts are labeled constructed, not
machine-checked, and no test deletion is recommended.

Related findings: F5.
