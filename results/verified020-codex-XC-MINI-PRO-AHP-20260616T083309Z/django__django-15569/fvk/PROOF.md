# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims

The constructed K artifacts are:

- `mini-lookup-cache.k`: mini state-transition semantics for lookup registry
  mutation and cache invalidation.
- `register-lookup-spec.k`: reachability claims for unregister cache clearing
  and later recomputation.

Primary claim:

`UNREGISTER-CLEARS-DESCENDANT-CACHES`

For any class `C`, lookup name `N`, registry `REG`, cache map `CACHE`, and
inclusive descendant set `DESC`, if `(C, N)` is present in `REG`, executing
`unregisterLookup(C, N)` reaches a state where `(C, N)` is absent and cache
entries for all classes in `DESC` are invalidated.

Derived claim:

`GET-LOOKUPS-RECOMPUTES-AFTER-UNREGISTER`

For any descendant `D` in `DESC`, a later `getLookups(D)` is not allowed to use
the old cached map. It must recompute from current MRO registries.

## Proof Sketch

1. Start from a state satisfying O-001: `lookupKey(C, N)` is present in the
   registry and `DESC` is the inclusive descendant set for `C`.
2. Apply the `unregisterLookup(C, N)` transition from `mini-lookup-cache.k`.
3. The transition rewrites the registry cell from `REG` to
   `REG[lookupKey(C, N) <- absent]`, discharging O-002.
4. The transition rewrites the cache cell from `CACHE` to
   `clearCaches(CACHE, DESC)`.
5. By induction over the finite `DESC` set:
   - Base: clearing `.Set` returns the cache unchanged.
   - Step: clearing `SetItem(D) REST` rewrites `cacheKey(D)` to `uncached`,
     then clears `REST`.
   Therefore every class in `DESC` has an invalidated cache entry, discharging
   O-003 and O-006.
6. Since `get_lookups()` is an `lru_cache`, clearing the cache entry means the
   next lookup call executes the merge logic again. The merge reads current
   `class_lookups` values from the MRO, where `lookupKey(C, N)` is now absent.
   This discharges O-004.
7. The transition does not change method arguments, absent-key behavior before
   a successful delete, or unrelated registry entries, discharging O-005.
8. Source callsites preserve the same signature and gain method-owned cache
   invalidation, discharging O-007.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` paraphrases both claims. `SPEC_AUDIT.md` marks them as
passing against `INTENT_SPEC.md`; no formal claim depends on the stale V0 cache
behavior. `PUBLIC_COMPATIBILITY_AUDIT.md` finds no unhandled public callsite or
override compatibility issue.

## Test Recommendation

No tests were modified. Existing tests that only assert successful temporary
lookup unregister cleanup would be candidates for proof subsumption only after
the K claims are machine-checked. Tests covering integration with Django query
construction, database backends, or application install/uninstall behavior
should be kept because the mini semantics covers only lookup registry/cache
state.

## Reproduce the Machine Check Later

These commands are recorded for a future environment with K installed. They
were not run in this session.

```sh
cd fvk
kompile mini-lookup-cache.k --backend haskell
kast --backend haskell register-lookup-spec.k
kprove register-lookup-spec.k
```

Expected result after machine checking: `#Top` for the stated claims. Until
then, this remains a constructed proof only.

## Residual Risk

- The model is a mini semantics of the lookup registry/cache state, not full
  Python or full Django query execution.
- Partial correctness only: the proof establishes the post-state if the helper
  completes normally.
- Thread safety is explicitly outside the method's docstring contract.
- Machine checking has not been performed.

