# FVK Spec

Status: constructed, not machine-checked.

## Target

`repo/lib/matplotlib/contour.py`, `ContourSet.set_paths(self, paths)`.

## Intent-derived contract

For any `ContourSet` and any supplied path sequence in the public domain,
`set_paths(paths)` must:

1. replace the contour path sequence with exactly `paths`;
2. make subsequent `get_paths()` and `_paths` consumers observe `paths`;
3. mark the artist stale;
4. invalidate old-style split collection cache data derived from the previous
   `_paths`;
5. leave unrelated contour metadata and collection subclasses untouched.

No path copying, conversion, or validation is required by the public issue or by
the `PathCollection.set_paths` hint.

## Public intent ledger

The ledger is duplicated in `PUBLIC_EVIDENCE_LEDGER.md`.  The critical entries
are:

- E1/E2/E3: the issue proposes `cs.set_paths(transformed_paths)` as the clean
  form of replacing `cs.get_paths()[:]`.
- E4: the public hint points to `PathCollection.set_paths`, which assigns
  `_paths` and sets `stale`.
- E6: existing contour code invalidates `_old_style_split_collections` before a
  path mutation, establishing that the cache is derived state.
- E7: other collection subclasses have specialized setters, so the repair
  should not broaden base `Collection.set_paths`.

## Formal model

`mini-python-contour-set.k` models only the state that this setter can affect:
the path sequence, stale flag, old-style cache state, and an opaque frame cell
for unrelated contour state.

`contour-set-set-paths-spec.k` contains one reachability claim,
`CSET-SET-PATHS`: executing `set_paths(NEW)` terminates with paths equal to
`NEW`, stale true, cache absent, and unrelated state unchanged.

