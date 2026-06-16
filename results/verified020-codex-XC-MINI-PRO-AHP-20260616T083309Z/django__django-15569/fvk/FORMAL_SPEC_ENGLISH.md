# FORMAL_SPEC_ENGLISH

## Claim: UNREGISTER-CLEARS-DESCENDANT-CACHES

If a lookup name `N` is currently registered on class `C`, and `DESC` is the
inclusive set containing `C` and every subclass whose lookup cache may depend
on `C`, then executing `unregisterLookup(C, N)` removes the `(C, N)` registry
entry and marks every class cache in `DESC` as uncached.

The claim does not require idempotent behavior when `(C, N)` is absent.

## Claim: GET-LOOKUPS-RECOMPUTES-AFTER-UNREGISTER

After the unregister transition clears dependent caches, a later
`getLookups(D)` for any `D` in the descendant set cannot reuse the stale cached
lookup map. It must recompute from current MRO registries. The removed lookup
name is therefore absent from the result unless another still-registered class
in the MRO supplies that name.

## Frame Conditions

The transition preserves the existing method signature, lookup name resolution
rules, missing-key exception behavior, unrelated registry entries, and
non-descendant cache entries.

