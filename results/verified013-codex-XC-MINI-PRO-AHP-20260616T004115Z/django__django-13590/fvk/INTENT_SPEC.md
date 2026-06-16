# Intent Spec

This file records intended behavior before accepting candidate implementation
behavior as the specification.

1. A standard two-field named tuple is a valid `__range` lookup argument.
2. Resolving a lookup value recursively resolves each element inside list,
   tuple, and named tuple containers.
3. The named tuple case must not raise the pre-fix constructor arity
   `TypeError`.
4. The named tuple result must be reconstructed with positional resolved
   elements, preserving the named tuple type.
5. Plain list and tuple behavior should remain compatible with the prior
   iterable-constructor path.
6. The `resolve_lookup_value()` signature and downstream iterable RHS protocol
   should not change.

Default-domain assumptions:

- The named tuple in scope is a standard Python named tuple shape: tuple
  instance plus `_fields`, with constructor arity matching its field count.
- Containers are finite.
- External expression resolution is outside this unit.
