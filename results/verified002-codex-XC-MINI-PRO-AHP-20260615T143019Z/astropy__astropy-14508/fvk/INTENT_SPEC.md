# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Public-intent obligations

1. `io.fits.Card` should be able to create any valid FITS card whose keyword,
   value, and comment fit in one 80-character card image.
2. For newly formatted floating-point card values, prefer Python's shortest
   round-tripping string representation when it fits in the existing FITS
   numeric value budget.
3. The concrete value `0.009125` must serialize as `0.009125`, not as
   `0.009124999999999999`.
4. The concrete card
   `HIERARCH ESO IFM CL RADIUS = 0.009125 / [m] radius arround actuator to avoid`
   must be creatable without warning-driven comment truncation.
5. Existing FITS-facing numeric formatting constraints remain in force:
   exponent markers used in output should be normalized to uppercase `E`, plain
   non-exponent numeric values should contain a decimal point, and the helper's
   value token remains capped at 20 characters.
6. Existing parsed cards that carry an original `_valuestring` and are not
   value-modified should keep that original value string.
7. No public API signature, return type, or test-file contract should be changed
   to implement this fix.

## Domain

The formalized unit is the newly formatted floating-value path used by
`_format_value()` and, through `Card._format_image()`, by HIERARCH card
construction. The model abstracts Python float-to-string conversion as two
publicly relevant string views: `str(value)` and the legacy `.16G` fallback.
It verifies the selection, normalization, and capping logic changed by V1.
