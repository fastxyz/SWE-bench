# FVK Findings

Status: constructed, not machine-checked.

## F1 - Missing concrete ContourSet setter in pre-fix code

Input: an in-domain `ContourSet` `cs` and a sequence `transformed_paths`,
calling `cs.set_paths(transformed_paths)`.

Observed in the pre-fix code: dispatch reaches `Collection.set_paths`, which
raises `NotImplementedError`.

Expected from E1-E4: `ContourSet` accepts the call, replaces `_paths` with the
supplied sequence, and marks itself stale.

Classification: code bug / self-declared incompleteness on an in-domain input.

Resolution: fixed by adding `ContourSet.set_paths`.

## F2 - V1 missed old-style cache invalidation

Input: a `ContourSet` whose deprecated old-style split-collection cache has
been materialized, followed by `cs.set_paths(new_paths)`.

Observed in V1: `_paths` is replaced and `stale` is set, but
`_old_style_split_collections` remains present and can continue to expose path
views derived from the previous `_paths`.

Expected from E6 and the full path-replacement intent: replacing `_paths`
invalidates cache data derived from the previous path sequence.

Classification: code bug in V1 / stale derived state.

Resolution: fixed in V2 by deleting `_old_style_split_collections` when present,
matching the existing invalidation pattern used by contour labeling.

## F3 - Broad base-class setter change rejected

Input: any non-contour `Collection` subclass with specialized path construction,
calling its `set_paths` behavior.

Observed risk: changing `Collection.set_paths` to assign `_paths` generically
would alter the public behavior of unrelated subclasses.

Expected from E7: keep this enhancement scoped to `ContourSet`.

Classification: compatibility risk avoided.

Resolution: no base-class edit.

## Proof-derived findings

The constructed proof discharges the modeled setter obligations for V2.  No
additional code bug was found within the modeled behavior.  The result remains
constructed, not machine-checked; no tests were removed.

