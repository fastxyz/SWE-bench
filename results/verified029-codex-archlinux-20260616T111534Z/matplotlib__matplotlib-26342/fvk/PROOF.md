# Constructed Proof

Status: constructed, not machine-checked.  No K tooling was run.

## Claim

`CSET-SET-PATHS` in `contour-set-set-paths-spec.k` states that
`set_paths(NEW)` terminates with:

- paths changed from any `OLD` to `NEW`;
- stale changed from any boolean to `true`;
- cache changed from either `cacheAbsent` or `cachePresent` to `cacheAbsent`;
- unrelated state unchanged.

## Symbolic proof sketch

Start with arbitrary `OLD`, `OLDSTALE`, `OLDCACHE`, `OTHER`, and `NEW`.

1. Expand `set_paths(NEW)` by the method-body rule:
   `ifCache then invalidateCache ; paths = NEW ; stale = true`.
2. Case split on `OLDCACHE`.
3. If `OLDCACHE = cachePresent`, `ifCache` executes `invalidateCache`, which
   rewrites the cache cell to `cacheAbsent`.
4. If `OLDCACHE = cacheAbsent`, `ifCache` rewrites to `.K`; the cache is already
   `cacheAbsent`.
5. Sequence execution continues with `paths = NEW`, which rewrites the paths
   cell to `NEW`.
6. Sequence execution continues with `stale = true`, which rewrites the stale
   cell to `true`.
7. The `<other>` frame cell is untouched by every rule, so it remains `OTHER`.

Both cache branches reach the post-state.  There are no loops or recursive
calls, so no circularity is required.

## Machine-check commands

These commands are emitted for later checking only and were not run:

```sh
kompile fvk/mini-python-contour-set.k --backend haskell
kast --backend haskell fvk/contour-set-set-paths-spec.k
kprove fvk/contour-set-set-paths-spec.k
```

Expected machine-check result after a valid local K setup: `#Top`.

## Test recommendation

Do not remove tests.  After machine-checking, focused unit tests that only
assert `set_paths` replaces `_paths`, marks stale, and invalidates the cache
would be subsumed by this proof.  Rendering, integration, deprecation, and
backend tests should be kept because the mini semantics does not model them.

