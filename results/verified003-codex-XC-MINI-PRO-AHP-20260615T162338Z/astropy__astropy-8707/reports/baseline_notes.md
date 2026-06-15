# Baseline Notes

## Root Cause

`Header.fromstring` documented that it accepted a byte string containing FITS
header data, but the implementation treated the input as text throughout. On
Python 3, passing `bytes` caused byte slices to be compared with text literals
and eventually joined with `''.join(...)`, which is invalid for byte fragments.
Likewise, `Card.fromstring` stored a raw `bytes` image directly; later parsing
uses text regular expressions and text padding, so bytes input was not a valid
path there either.

## Files Changed

`repo/astropy/io/fits/header.py`

`Header.fromstring` now normalizes `data` and `sep` with the existing
`decode_ascii` helper before splitting cards. This makes Python 3 `bytes`
input follow the same ASCII decoding and non-ASCII warning/replacement behavior
used when headers are read from binary files.

`repo/astropy/io/fits/card.py`

`Card.fromstring` now normalizes `image` with `decode_ascii` before padding and
storing the raw card image. The import list was extended to include
`decode_ascii`, and the docstring now describes `str` or `bytes` input.

## Assumptions and Alternatives

I assumed FITS header and card images should be decoded as ASCII at these API
boundaries because the FITS header format is ASCII and the surrounding
`fromfile` implementation already uses `decode_ascii` after reading binary
blocks.

I also decoded `sep` when it is supplied as bytes, even though the issue focuses
on the header/card data itself. That keeps `Header.fromstring(data, sep=b'\n')`
consistent with `Header.fromstring(data, sep='\n')` and avoids mixed
bytes/text operations after the data is decoded.

I rejected a larger rewrite that would make the splitting logic operate on
bytes internally, because the rest of the card parser is text-oriented and
already has a shared helper for converting FITS bytes to text.
