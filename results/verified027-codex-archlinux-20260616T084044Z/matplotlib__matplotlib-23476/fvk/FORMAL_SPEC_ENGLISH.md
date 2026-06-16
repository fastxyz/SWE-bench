# Formal Spec English

Status: paraphrase of `fvk/figure-pickle-spec.k`; constructed, not
machine-checked.

## Claims

1. `GETSTATE-HIDPI-LOGICAL`

If a figure is in high-DPI runtime state with live DPI `L * R`, logical DPI `L`,
device pixel ratio `R > 1`, and transform scale `L * R`, then serializing the
figure stores DPI `L` and original DPI `L`. The old high-DPI transform scale may
still be present in the raw pickle state, but it is not trusted after load.

2. `GETSTATE-RATIO-ONE-PRESERVES-CURRENT-DPI`

If a figure is on a ratio-1 canvas, serializing stores current DPI `D`. It does
not replace current DPI with `_original_dpi`.

3. `SETSTATE-RESYNCS-DPI-TRANSFORM`

If a pickle stores DPI `P`, then unpickling restores live DPI `P`, resets the
base canvas logical DPI to `P`, sets canvas ratio to `1`, and makes the DPI
transform scale `P`, regardless of any stale transform scale that was present in
the raw pickle state.

4. `ROUNDTRIP-HIDPI-SAME-RATIO-IDEMPOTENT`

For high-DPI state `D = L * R` with `R > 1`, serializing, unpickling, and
reattaching to a backend with the same ratio `R` produces live DPI `L * R`. The
result is equal to the starting live DPI, not multiplied by `R` again.

5. `ROUNDTRIP-RATIO-ONE-PRESERVES-DPI`

For a ratio-1 canvas, serializing and unpickling preserves the current DPI `D`
and transform scale `D`.

6. `ROUNDTRIP-HIDPI-LOAD-RATIO-ONE-USES-LOGICAL-DPI`

For a high-DPI pickle loaded without a high-DPI backend ratio, the resulting
base-canvas figure uses logical DPI `L`. This is expected because no backend is
present to reapply a device pixel ratio.

## Frame Conditions

The formal claims do not change public method signatures, manager restoration
control flow, or backend-specific `_set_device_pixel_ratio` behavior. They only
constrain the DPI-related fields carried through figure serialization.
