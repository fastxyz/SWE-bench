# Baseline Notes

## Root cause

`astropy.io.fits.card._format_float()` formatted newly-created floating-point
card values with `f"{value:.16G}"`. For values such as `0.009125`, that format
exposes the binary approximation as `0.009124999999999999` instead of using
Python's shortest round-tripping string representation. In a HIERARCH card,
those unnecessary extra digits can consume enough of the 80-character card to
force an otherwise valid comment to be truncated.

## Changed files

- `repo/astropy/io/fits/card.py`: changed `_format_float()` to first try
  `str(value)` so floats use Python's shortest round-tripping representation
  when it fits in the FITS value field. If that string is longer than 20
  characters, the previous `.16G` formatting remains the compact fallback. The
  existing cleanup still runs afterward: plain numeric values receive a decimal
  point when needed, exponent markers are normalized for FITS output, and the
  value string remains capped at 20 characters.

## Assumptions

- Python's float string representation is the desired default for new FITS card
  serialization when it fits because it is short while preserving round-trip
  identity for normal Python floats.
- FITS output should continue to use uppercase exponent markers, since the
  verifier's standard-value regex accepts uppercase `E`/`D` and existing code
  already normalizes exponent strings to uppercase during fixes.
- The existing 20-character value-field cap is still required and should remain
  unchanged.

## Alternatives considered

- Replacing the entire formatter with raw `str(value)` was rejected because it
  can exceed the 20-character FITS value field and Python emits lowercase `e`
  in scientific notation, while existing FITS standard verification expects
  uppercase exponent markers.
- Keeping `.16G` and adding a special case for `0.009125`-style values was
  rejected because the issue is general: the formatter should prefer Python's
  shortest representation for all floats before applying FITS-specific cleanup.
- Adding or modifying visible tests was not done because this benchmark task
  explicitly forbids modifying test files.
