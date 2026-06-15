# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | Problem | "when I perform a `world_to_pixel` on the full (unsliced) WCS, I get back the expected result" | The wrapped WCS inverse is the reference for on-slice consistency. | Encoded in SPEC and K claim C1. |
| E2 | Problem | "I would then expect ... a single wavelength slice ... get back the same first two components" | A sliced inverse must return the kept pixel coordinates from the corresponding full-WCS inverse. | Encoded in SPEC and K claim C1. |
| E3 | Public hint | "the value of `1` here is incorrect, it needs to be the world coordinate corresponding to the pixel value in the slice" | Dropped world coordinates in `world_to_pixel_values` must come from the fixed pixel slice, not from a constant placeholder. | Encoded in SPEC and K claims C1/C2; finding F1. |
| E4 | Low-level API docstring | "`world_to_pixel_values`: Convert world coordinates to pixel coordinates" and returns pixel coordinates in pixel order. | Preserve the low-level API shape and coordinate ordering. | Encoded as frame condition O5/O6. |
| E5 | `SlicedLowLevelWCS` docstring | The wrapper "applies an array slice to a WCS" and "stores which pixel and world dimensions have been sliced out". | The wrapper must construct full wrapped-WCS coordinates by re-inserting sliced-out dimensions. | Encoded in SPEC and K semantics. |
| E6 | `axis_correlation_matrix` docstring | The matrix indicates "whether a given world coordinate depends on a given pixel coordinate." | World axes omitted by `_world_keep` are treated as independent of kept pixels under this matrix. | Domain assumption for O2. |
| E7 | Public tests | Existing sliced tests assert `dropped_world_dimensions["value"]` equals the fixed-slice world value. | Metadata and inverse transform should share the same fixed-slice source. | Supporting evidence for O4; not used to preserve legacy bug behavior. |

SUSPECT legacy behavior: the pre-fix `world_to_pixel_values` placeholder `1.0`
is explicitly identified by the public hint as incorrect, so no claim preserves
that behavior.
