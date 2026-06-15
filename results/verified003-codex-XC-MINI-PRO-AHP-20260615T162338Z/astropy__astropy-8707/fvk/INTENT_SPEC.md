# Intent Specification

Status: constructed from public intent before accepting candidate behavior as
the specification.

## Scope

This FVK pass audits the public boundary behavior of:

- `astropy.io.fits.Header.fromstring`
- `astropy.io.fits.Card.fromstring`

The audited property is input type handling at the raw FITS header/card parsing
boundary. The existing text parser's detailed FITS grammar behavior is treated
as preserved behavior, not reproved here.

## Required Behavior

IS-1. `Header.fromstring` accepts Python `str` input containing a complete FITS
header.

IS-2. `Header.fromstring` accepts Python 3 `bytes` input containing the same
ASCII FITS header bytes and parses it as the equivalent text header.

IS-3. `Header.fromstring` preserves existing behavior for text input and for
normal card separators such as `sep=''` and `sep='\n'`.

IS-4. If a separator is supplied as bytes, it should be normalized to the same
text separator before splitting cards. This is a compatibility extension of the
same bytes-as-ASCII boundary rule; it avoids mixed bytes/text operations.

IS-5. `Card.fromstring` accepts Python `str` input containing a raw card image.

IS-6. `Card.fromstring` accepts Python 3 `bytes` input containing an ASCII card
image and parses it as the equivalent text card image.

IS-7. Direct bytes input should use the same ASCII decoding policy as binary
header data read from files: ASCII bytes decode directly; non-ASCII bytes follow
the existing `decode_ascii` warning/replacement policy.

IS-8. The repair should not add new public APIs or change public call
signatures. It should be a minimal extension of accepted input types.

