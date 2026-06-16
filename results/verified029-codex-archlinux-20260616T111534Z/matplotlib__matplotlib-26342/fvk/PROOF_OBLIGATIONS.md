# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Path replacement

For all initial path states `OLD` and supplied path sequences `NEW`, executing
`set_paths(NEW)` leaves the contour path state equal to `NEW`.

Evidence: E1-E3.

## PO2 - Stale propagation

For all initial stale flag values, executing `set_paths(NEW)` leaves `stale`
equal to `true`.

Evidence: E4.

## PO3 - Derived cache invalidation

For both old-style cache states, absent and present, executing `set_paths(NEW)`
leaves the cache absent.

Evidence: E6 and Finding F2.

## PO4 - Frame condition

Unrelated contour state is unchanged by `set_paths`.

Evidence: setter body only touches `_old_style_split_collections`, `_paths`, and
`stale`.

## PO5 - Compatibility boundary

The repair must not change base `Collection.set_paths` or specialized collection
setter semantics.

Evidence: E7 and Finding F3.

## PO6 - Adequacy

The formal claim must distinguish a passing implementation from V1.  A model
where the final cache state remains `cachePresent` for an initially present
cache fails PO3, so the model observes the V1 defect.

