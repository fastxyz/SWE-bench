# Intent Spec

Status: constructed, not machine-checked.

Required behavior from public evidence:

1. Pickling and unpickling `QuerySet.query`, then assigning it with `qs.query = query`, is a supported way to re-run a query later.
2. A `values()` query restored by that workflow must evaluate with dict-shaped results, not model instances.
3. A `values().annotate()` query restored by that workflow must preserve dict-shaped results including annotation columns.
4. A `values_list()` query restored by that workflow must preserve the appropriate values-list result shape: tuple, flat scalar, or namedtuple.
5. The repair target is production source code, not tests or a documentation-only warning.
6. When exact values-list mode information is absent from the query, exact recovery is not derivable; the minimum safe behavior is to avoid `ModelIterable` for selected query rows.

