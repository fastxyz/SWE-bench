# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed symbol

- `astropy.io.fits.card._format_float(value)`: private helper; signature
  unchanged; return type remains `str`.

## Public entry points affected

- `astropy.io.fits.Card(...)` construction and string rendering through
  `Card.image`/`str(Card)`.
- Header operations that eventually construct or format `Card` objects.

## Compatibility checks

- No public method signature changed.
- No virtual dispatch call was given a new argument.
- No new dependency or import was added.
- Existing parsed-card value preservation remains guarded by `_valuestring` and
  `_valuemodified` in `Card._format_value()`, so unmodified cards read from
  files retain their original textual numeric representation.
- FITS standard verification remains compatible because selected lowercase
  exponent markers are normalized to uppercase `E` before returning the token.

## Result

Pass. The change is behaviorally visible only as shorter newly generated float
tokens where public intent requires them.
