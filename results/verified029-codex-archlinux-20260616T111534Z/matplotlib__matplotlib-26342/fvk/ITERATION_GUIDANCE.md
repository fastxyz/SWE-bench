# Iteration Guidance

Status: V2 source is recommended.

## Source decision

Keep the scoped `ContourSet.set_paths` implementation and the V2 cache
invalidation.  The FVK audit found no need to change `Collection.set_paths` or
to add path conversion/copying.

## Suggested public tests for a normal development environment

Do not edit tests in this benchmark.  In a normal repo workflow, useful tests
would assert:

1. `cs.set_paths(new_paths)` does not raise.
2. `cs.get_paths()` returns the exact supplied sequence.
3. `cs.stale` is true after the call.
4. If `_old_style_split_collections` was present before the call, it is absent
   afterward.

## Residual risk

The proof is constructed, not machine-checked.  The mini semantics also does not
model rendering backends, path geometry validity, or legacy already-added
PathCollection artists on the axes after deprecated `.collections` access.
Those are outside the public issue's setter-equivalence contract and should be
covered by integration tests rather than by this small unit proof.

## Next commands

When a K environment exists, run:

```sh
kompile fvk/mini-python-contour-set.k --backend haskell
kast --backend haskell fvk/contour-set-set-paths-spec.k
kprove fvk/contour-set-set-paths-spec.k
```

