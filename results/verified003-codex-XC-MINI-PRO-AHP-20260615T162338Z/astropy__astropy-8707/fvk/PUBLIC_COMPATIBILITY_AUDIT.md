# Public Compatibility Audit

Status: source-read audit; no code or tests executed.

## Changed Public Symbols

`Header.fromstring(data, sep='')`

- Signature changed: no.
- Return shape changed: no.
- Accepted input domain changed: yes, expanded to include ASCII `bytes` for
  `data` and, compatibly, for `sep`.
- Public/internal callsites inspected: `Header._from_blocks`, FITS diffing,
  header pickling helpers, and public tests under `astropy/io/fits/tests`.
- Compatibility result: pass. Existing callsites pass `str` values and continue
  through the same text parser because `decode_ascii(str)` is identity.

`Card.fromstring(image)`

- Signature changed: no.
- Return shape changed: no.
- Accepted input domain changed: yes, expanded to include ASCII `bytes`.
- Public/internal callsites inspected: `Header.fromstring`, `_CardAccessor`,
  header update helpers, and public tests under `astropy/io/fits/tests`.
- Compatibility result: pass. Existing callsites pass `str` slices/images and
  continue through the same padding and lazy parse path.

## Not Changed

`HeaderDiff` accepts `Header` instances or `str` headers and only dispatches
`Header.fromstring` for `isinstance(x, str)`. This FVK pass does not require
changing `HeaderDiff`; the public issue targets `Header.fromstring` and
`Card.fromstring` directly.

## Result

No unhandled public callsite, subclass override, signature mismatch, or
producer/consumer shape mismatch was found.

