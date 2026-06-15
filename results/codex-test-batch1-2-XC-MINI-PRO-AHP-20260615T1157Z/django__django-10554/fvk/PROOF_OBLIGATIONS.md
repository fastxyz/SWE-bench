# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Combined-query children are not aliased across derivation

For a combined source query `orig` and a derived query `derived`,
`derived.combined_queries[i]` must be a clone of `orig.combined_queries[i]`,
not the same object.

Discharged by V1: `Query.clone()` sets:

```python
obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

## PO-2: Derived select-list narrowing frames the source query

If a derived `values_list('pk')` query narrows derived component select lists to
width `1`, the source ordered union's component select lists remain width `4`
in the issue model.

Discharged by PO-1 plus the existing compiler behavior that applies `set_values`
to the query being compiled, not to every alias in the object graph.

## PO-3: Original ordered union remains orderable

After derived evaluation, every component query used by the original ordered
union must still contain the order position. In the issue model:

```text
order_position(orig) = 4
width(c1) = 4
width(c2) = 4
```

Therefore `4 <= 4` for each component and `assertOrderable(orig)` succeeds.

## PO-4: Recursive/nested combined queries are isolated

If a component query is itself combined, cloning `combined_queries` must recurse
so mutations under the derived tree do not reach the source tree.

Discharged by V1 because `query.clone()` is called for every component, and each
component's `clone()` applies the same rule.

## PO-5: Public compatibility is preserved

The fix must not change public method signatures, return shapes, or the tuple
shape of `combined_queries`.

Discharged by V1 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: `combined_queries`
remains a tuple of `Query` objects, only with cloned entries.

## PO-6: No execution/tooling assumptions

Because this task forbids tests and K tooling, the proof must remain a
constructed proof with exact unexecuted commands.

Discharged in `fvk/PROOF.md`.
