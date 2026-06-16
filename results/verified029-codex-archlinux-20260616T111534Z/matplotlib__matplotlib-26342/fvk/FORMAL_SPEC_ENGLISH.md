# Formal Spec English

This paraphrases the K claims in `contour-set-set-paths-spec.k`.

## CSET-SET-PATHS

For any initial contour path sequence, any stale flag value, any old-style cache
state, and any supplied path sequence `NEW`, executing the modeled
`set_paths(NEW)` body terminates with:

- `_paths` equal to `NEW`;
- `stale` equal to `true`;
- the old-style split-collection cache absent;
- unrelated contour state unchanged.

The claim has no loop circularities and no path-shape validation precondition.

