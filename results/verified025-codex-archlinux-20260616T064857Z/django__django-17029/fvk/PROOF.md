# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Claims proved

The constructed proof covers the claims in `fvk/apps-registry-spec.k`:

- `CLEAR-CACHE-READY`
- `CLEAR-CACHE-NOT-READY`
- `LOOKUP-AFTER-CLEAR-READY`
- `LOOKUP-AFTER-CLEAR-NOT-READY`
- `MUTATE-CLEAR-LOOKUP-READY`
- `MUTATE-CLEAR-LOOKUP-NOT-READY`

There are no loops or recursive functions in the audited code slice, so no
circularity claim is required. The proof is straight-line symbolic execution
with a ready-state case split.

## Proof sketch

1. `clear_cache` rewrites to the sequence
   `clear_get_models_cache; clear_swappable_settings_name_cache;
   expire_model_meta_if_ready`.

2. `clear_get_models_cache` rewrites `modelsCacheVersion` to `-1`.

3. `clear_swappable_settings_name_cache` rewrites
   `swappableCacheVersion` to `-1`.

4. `expire_model_meta_if_ready` case-splits on `ready`:

   - when `ready == true`, it rewrites `metaCachesExpired` to `true`;
   - when `ready == false`, it terminates without rewriting
     `metaCachesExpired`.

5. Therefore `CLEAR-CACHE-READY` and `CLEAR-CACHE-NOT-READY` reach the claimed
   final states by transitivity over the three operations.

6. For `LOOKUP-AFTER-CLEAR-*`, after steps 1-4 the swappable cache is empty
   (`-1`). The lookup rule for an empty swappable cache reads
   `registryVersion`, writes that version into `swappableCacheVersion`, and
   writes the same version into `lookupObservedVersion`. The stale-cache lookup
   rule is not applicable because its side condition requires a cache version
   different from `-1`.

7. For `MUTATE-CLEAR-LOOKUP-*`, `mutate_registry` first rewrites
   `registryVersion` from `RV` to `RV + 1`. The subsequent `clear_cache` empties
   the swappable cache in both ready branches. The lookup then uses the
   empty-cache rule and observes `RV + 1`, not the pre-mutation or pre-clear
   cache version.

## Verification conditions

- VC-001: `clear_get_models_cache` sets `modelsCacheVersion` to `-1`.
  Discharged directly by the semantics rule.
- VC-002: `clear_swappable_settings_name_cache` sets
  `swappableCacheVersion` to `-1`. Discharged directly by the semantics rule.
- VC-003: ready branch preserves existing model-meta cache behavior. Discharged
  by case split on `ready`.
- VC-004: lookup after clear observes current registry version. Discharged by
  the empty-cache lookup rule.
- VC-005: mutation plus clear plus lookup observes the mutated registry version.
  Discharged by transitivity and integer substitution `RV := RV + 1`.

No nonlinear arithmetic, map extensionality, loop invariant, or termination
obligation is present in this audited slice.

## Adequacy check

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims. `fvk/SPEC_AUDIT.md`
compares that paraphrase with `fvk/INTENT_SPEC.md`; all entries pass. The model
does not prove a candidate-derived behavior: the cache-clearing requirement is
derived from the issue text and the `clear_cache()` docstring.

## Reproduce the machine check later

The commands below are recorded for a future environment with K installed. They
were not executed in this session.

```sh
kompile fvk/mini-python-cache.k --backend haskell
kast --backend haskell fvk/apps-registry-spec.k
kprove fvk/apps-registry-spec.k
```

Expected `kprove` result: `#Top` for all claims.

## Test recommendation

Do not remove tests from this benchmark. The task forbids modifying tests, and
this proof is constructed rather than machine-checked. A future test that
asserts `clear_cache()` clears `get_swappable_settings_name()`'s cache would be
subsumed by PO-001 and PO-002 only after the K commands above successfully
return `#Top`.
