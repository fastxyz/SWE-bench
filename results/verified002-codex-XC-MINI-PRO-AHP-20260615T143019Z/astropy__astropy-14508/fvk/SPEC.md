# FVK Spec

Status: constructed for FVK audit; not machine-checked.

## Target

The audited unit is `astropy.io.fits.card._format_float(value)` and its
observable contribution to `Card._format_image()` for newly constructed FITS
cards. The V1 patch is:

```python
value_str = str(value).replace("e", "E")
if len(value_str) > 20:
    value_str = f"{value:.16G}"
```

followed by the existing decimal-point, exponent-normalization, and 20-character
capping logic.

## Intent ledger

See `PUBLIC_EVIDENCE_LEDGER.md`. The decisive entries are:

- E4: `0.009125` must serialize as `0.009125`, not as
  `0.009124999999999999`.
- E5: `str(value)` should be attempted before `.16G`; `.16G` is a fallback when
  `str(value)` does not fit in 20 characters.
- E7/E8: exponent normalization and the 20-character cap remain part of the
  intended FITS-facing helper behavior.
- E9: parsed, unmodified `_valuestring` values are a frame condition and should
  not be reformatted by this path.

## Formal domain

The K model represents a float as `floatView(S, Legacy)`, where:

- `S` is the token produced by Python `str(value)`.
- `Legacy` is the token produced by the previous `.16G` formatting path.

The proof is over the straight-line selection and normalization logic:

```text
short = replace_lowercase_e(S)
base = short if len(short) <= 20 else Legacy
token = cap20(normalizeExponent(ensureDecimal(base)))
```

This abstraction is property-complete for the defect: the failing and passing
instances differ only by whether the selected token is `Legacy` or `S`, and
that choice is explicitly observable in the model.

## Claims

- `SHORT-REP-PREFERENCE`: if normalized `str(value)` has length at most 20,
  `_format_float` uses that token, then applies the existing cleanup.
- `LEGACY-FALLBACK`: if normalized `str(value)` is longer than 20, `_format_float`
  falls back to the previous `.16G` token, then applies the existing cleanup.
- `REPORTED-FLOAT`: the issue value maps to `0.009125`.
- `REPORTED-HIERARCH-CARD`: the reported HIERARCH card image fits with the full
  comment.
- `EXPONENT-NORMALIZATION`: lowercase exponent text selected from `str(value)` is
  converted to uppercase before output.
- `PARSED-VALUESTRING-FRAME`: existing unmodified parsed value strings bypass
  `_format_float` through the pre-existing `_valuestring` branch in
  `Card._format_value()`.

## Machine-check commands

These commands are emitted for later checking only; they were not run here.

```sh
kompile fvk/mini-fits-card-format.k --backend haskell
kast --backend haskell fvk/fits-card-format-spec.k
kprove fvk/fits-card-format-spec.k
```
