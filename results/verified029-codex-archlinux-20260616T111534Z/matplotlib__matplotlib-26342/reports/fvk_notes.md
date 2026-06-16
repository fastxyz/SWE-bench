# FVK Notes

## Decisions

1. Kept the V1 decision to implement `ContourSet.set_paths` rather than
   changing `Collection.set_paths`.
   - Trace: `fvk/FINDINGS.md` F1 identifies the missing contour setter as the
     in-domain bug; F3 identifies a broad base-class edit as a compatibility
     risk.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2 require path
     replacement and stale propagation; PO5 requires preserving the collection
     compatibility boundary.

2. Revised V1 to invalidate `_old_style_split_collections` before replacing
   `_paths`.
   - Trace: `fvk/FINDINGS.md` F2 records that V1 left derived old-style path
     cache state present after `_paths` replacement.
   - Obligation: `fvk/PROOF_OBLIGATIONS.md` PO3 requires the cache to be absent
     after `set_paths` for both initially-present and initially-absent cache
     states.
   - Source change: `repo/lib/matplotlib/contour.py` now deletes
     `_old_style_split_collections` when present, matching the existing
     contour-labeling invalidation pattern.

3. Did not add path validation, copying, or conversion.
   - Trace: `fvk/SPEC.md` and `fvk/SPEC_AUDIT.md` tie the public issue to the
     existing workaround and `PathCollection.set_paths` hint, both of which
     support direct assignment semantics.
   - Obligation: PO1 only requires the final path state to be exactly the
     supplied sequence; adding validation or copying would be unsupported by
     public intent.

4. Did not modify tests or run any code.
   - Trace: `fvk/PROOF.md` labels the proof constructed, not machine-checked,
     and `fvk/ITERATION_GUIDANCE.md` lists suggested tests for a normal
     development environment only.
   - Constraint: the benchmark forbids test edits and code execution.

## Result

V2 satisfies the FVK contract over the modeled setter behavior: final `_paths`
is the supplied path sequence, `stale` is true, derived old-style path cache is
invalidated, and unrelated contour state and collection subclasses are left
alone.  The proof remains constructed, not machine-checked.

