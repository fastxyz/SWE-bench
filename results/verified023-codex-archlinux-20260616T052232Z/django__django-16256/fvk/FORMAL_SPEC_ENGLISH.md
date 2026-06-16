# Formal Spec English

Status: constructed, not machine-checked.

The K model in `mini-related-manager.k` abstracts the Django implementation to
the observable property under audit: async method lookup on a manager either
selects a local related-manager async wrapper, which delegates to the matching
synchronous related-manager method, or falls back to the copied queryset proxy.

Claim C1, reverse many-to-one: For every operation in
`{create, getOrCreate, updateOrCreate}`, invoking the async operation on a
reverse many-to-one manager reaches `reverseFkEffect(operation)`. It does not
reach `querysetProxyEffect(operation)`.

Claim C2, many-to-many: For every operation in
`{create, getOrCreate, updateOrCreate}` and for every abstract
`through_defaults` value, invoking the async operation on a many-to-many manager
reaches `manyToManyEffect(operation, through_defaults)`. The
`through_defaults` value in the final effect is the same value supplied to the
async call.

Claim C3, generic relation: For every operation in
`{create, getOrCreate, updateOrCreate}`, invoking the async operation on a
generic related manager reaches `genericEffect(operation)`. It does not reach
`querysetProxyEffect(operation)`.

Claim C4, plain manager frame: For every operation in the same async family,
invoking the operation on a plain manager still reaches
`querysetProxyEffect(operation)`. The repair does not rely on changing
`BaseManager._get_queryset_methods()`.

Claim C5, mutability marker: For each related manager family and operation, the
async method is marked as altering data.

