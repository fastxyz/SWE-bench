# FVK Notes

## Summary

The FVK audit confirmed the core V1 repair: `world_to_pixel_values` must supply
the wrapped WCS with fixed-slice world values for dropped world axes instead of
the old `1.0` placeholder. The audit also found that V1's private helper should
not be a `lazyproperty` used by the transform path, because caching was not part
of the public intent and could make inverse transforms depend on stale wrapped
WCS state. V2 keeps the semantic repair and changes the helper to a regular
method.

## Decisions

1. Kept the fixed dropped-world reconstruction in `world_to_pixel_values`.

   Evidence: `fvk/FINDINGS.md` F1 records the original bug, and
   `fvk/PROOF_OBLIGATIONS.md` O2/O3 state that the dropped world value must be
   `p2w(W, expandPixelsAtSlicedZero(S))` so the reconstructed full world vector
   matches the on-slice full WCS world vector. This directly traces to the
   public issue and hint.

2. Changed `_world_values_at_sliced_pixel` from V1's cached `lazyproperty` to a
   regular method.

   Evidence: `fvk/FINDINGS.md` F2 identifies the cache as an unnecessary
   transform-path state dependency, and `fvk/PROOF_OBLIGATIONS.md` O7 requires
   avoiding added stale transform cache behavior. Recomputing the helper once
   per inverse call when dropped axes exist satisfies the proof obligation while
   preserving the fix.

3. Kept `dropped_world_dimensions` on the same fixed-slice source.

   Evidence: `fvk/PROOF_OBLIGATIONS.md` O2 and `fvk/SPEC.md` C3 require metadata
   consistency with the inverse transform. The public metadata property remains
   a `lazyproperty`, matching the previous public behavior; only the transform
   helper cache was removed.

4. Did not change public APIs, return shapes, `_pixel_keep`, `_world_keep`,
   broadcast handling, or slice-start adjustment.

   Evidence: `fvk/PROOF_OBLIGATIONS.md` O5/O6 and
   `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` mark these as compatibility frame
   conditions. The source edit only changes internal reconstruction of dropped
   world inputs.

5. Did not modify tests or run code.

   Evidence: the benchmark forbids test edits and states there is no execution
   environment. `fvk/FINDINGS.md` F4 records the desired regression test as a
   future test gap only, and `fvk/PROOF.md` labels the proof constructed, not
   machine-checked.

## Residual Risk

`fvk/FINDINGS.md` F3 is an explicit proof capability boundary. The K artifacts
prove the wrapper reconstruction logic abstractly under the wrapped WCS inverse
and correlation-matrix assumptions; they do not prove FITS/wcslib numerical
behavior or NumPy broadcasting internals. That is why integration tests should
remain even after a future machine check of the abstract K claims.
