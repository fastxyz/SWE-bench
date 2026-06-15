# FVK Specification

Status: constructed from public intent and current source, not machine-checked.

## Unit Under Audit

`repo/astropy/wcs/wcsapi/wrappers/sliced_wcs.py`

- `SlicedLowLevelWCS._pixel_to_world_values_all`
- `SlicedLowLevelWCS._world_values_at_sliced_pixel`
- `SlicedLowLevelWCS.dropped_world_dimensions`
- `SlicedLowLevelWCS.world_to_pixel_values`

No loops are present in the audited functions beyond fixed finite iteration over
axis indices. The proof is therefore a straight symbolic data-flow proof rather
than a loop-circularity proof.

## Notation

- `W` is the wrapped low-level WCS.
- `S` is the sanitized slice vector in pixel order.
- `PK` is `_pixel_keep`.
- `WK` is `_world_keep`.
- `expandPixels(S, p)` inserts fixed integer slice pixels and adds range-slice
  starts to kept sliced pixels, producing the full wrapped-WCS pixel vector.
- `zeroSlicedPixels(S)` is a zero vector with one element per kept sliced pixel.
- `fixedWorld(W, S) = W.pixel_to_world_values(expandPixels(S, zeroSlicedPixels(S)))`.
- `selectWorld(v, WK)` selects the kept world components.
- `mergeWorld(WK, inputWorld, fixedWorld)` inserts caller-provided kept world
  values and fixed dropped world values into a full wrapped-WCS world vector.
- `adjustStarts(S, fullPixel)` subtracts range-slice starts from kept pixel axes.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- E2: sliced inverse returns the same kept pixel components as the full WCS for
  a point on the slice.
- E3: dropped world coordinates in inverse transforms must be the world
  coordinate at the fixed pixel slice, not a constant placeholder.
- E4/E5: public low-level WCS signatures, ordering, and slicing semantics remain
  unchanged.

## Formal Contract

### C1: Sliced Inverse Correctness

For every valid sliced WCS and kept sliced pixel vector `p` in the local inverse
domain:

```
world_to_pixel_values(selectWorld(W.pixel_to_world_values(expandPixels(S, p)), WK)) == p
```

This relies on:

- dropped world independence under `axis_correlation_matrix`;
- the wrapped WCS inverse on the constructed full world vector;
- start-offset correction before returning kept pixels.

### C2: Dropped World Source

For every dropped world axis `j`, `world_to_pixel_values` supplies
`fixedWorld(W, S)[j]` to the wrapped WCS. It must not supply an arbitrary numeric
placeholder.

### C3: Dropped Metadata Consistency

For every dropped world axis `j`, `dropped_world_dimensions["value"]` contains
`fixedWorld(W, S)[j]`, the same source used by C2.

### C4: API And Compatibility Frame

The fix must not alter:

- method signatures;
- the public return shape rules;
- `_pixel_keep` and `_world_keep` selection;
- slice-start adjustment behavior;
- public metadata keys in `dropped_world_dimensions`.

### C5: No Added Transform-State Cache

`world_to_pixel_values` must compute fixed dropped world values from the current
wrapped WCS state for the current call. The audit does not require caching, and a
cache in the transform path would be implementation-derived rather than
intent-derived.
