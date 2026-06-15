# FVK Iteration Guidance

Constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

The FVK audit found the original defect (F-001) and the main compatibility risk
from moving the cache (F-002). Both are discharged by the current source and the
proof obligations PO-1, PO-2, and PO-4. No finding requires a production-code
edit.

## Suggested Regression Tests

Do not edit tests in this benchmark task. For a normal Django patch, add focused
tests that:

1. Clear URL caches, call `get_resolver(None)`, then call
   `get_resolver(settings.ROOT_URLCONF)`, and assert object identity.
2. Include the omitted-argument form `get_resolver()` in the same identity
   family.
3. Confirm that `clear_url_caches()` invalidates the normalized helper cache.
4. Confirm that an explicit non-default URLconf does not collapse to the default
   resolver.

These tests are recommended because the proof was not machine-checked in this
environment.

## Machine Check Later

Commands recorded in `fvk/PROOF.md` should be run only in an environment with K
available:

```sh
kompile fvk/mini-resolver-cache.k --backend haskell
kast --backend haskell fvk/get-resolver-spec.k
kprove fvk/get-resolver-spec.k
```

Expected success token: `#Top`.

## Open Boundaries

F-004 records the unhashable-URLconf boundary. No change is recommended for this
issue because the documented `ROOT_URLCONF` is a string import path and explicit
unhashable arguments were already outside the public LRU-cached
`get_resolver(urlconf)` behavior.

F-005 records that the proof is constructed, not machine-checked. Keep all tests
until the formal artifacts are actually checked.
