# Iteration Guidance

## Verdict

V1 stands as V2. The FVK audit did not find a production-code defect that
justifies further source edits under the benchmark constraints.

## Why No Code Edit Was Applied

- FINDING F1 resolves the main intent conflict in favor of explicit
  topocentric ITRS, which is exactly the V1 design.
- PO1, PO2, PO3, PO4, PO6, PO7, PO8, and PO10 are discharged by static code
  inspection and the constructed K claims.
- FINDING F3 and FINDING F4 are precondition guards, not failures.
- FINDING F5 is a proof capability boundary for full Astropy/ERFA numeric
  semantics; it cannot be resolved by a local source edit without execution or
  a much larger formal semantics.

## Recommended Future Work

1. Add public tests, when execution is available, for:
   - `ITRS(topocentric_vector, location=home).transform_to(AltAz(location=home))`
     giving zenith for the straight-overhead example;
   - the analogous HADec result;
   - AltAz/HADec->`ITRS(location=home)` round trips;
   - pressure non-zero paths with valid `obstime`.
2. Update `docs/coordinates/common_errors.rst` to mention the new topocentric
   ITRS workflow alongside the existing CIRS workaround.
3. Run the emitted K commands if a K environment is available:

   ```sh
   kompile fvk/mini-coordinate-transforms.k --backend haskell
   kast --backend haskell fvk/itrs-observed-spec.k
   kprove fvk/itrs-observed-spec.k
   ```

4. Keep the existing test suite until the proof is machine-checked and the
   real numerical tests pass.
