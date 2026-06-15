# FVK Specification

Status: constructed, not machine-checked.

## Audited Unit

This specification covers the type-normalization boundary of:

- `Header.fromstring(data, sep='')`
- `Card.fromstring(image)`

The existing FITS text parser is abstracted as `parseHeader(Str(DATA),
Str(SEP))` and `makeCard(Str(IMAGE))`. This abstraction is property-complete
for the defect under audit because it preserves the observable axis that changed:
whether raw `bytes` reach the text parser as text or fail as bytes. It does not
attempt to prove all FITS grammar/card semantics.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2/E5 require `Header.fromstring` to accept Python 3 bytes as byte-string
  header data.
- E3 requires existing Unicode/text input behavior to remain valid.
- E4/E7/E8 identify `decode_ascii` as the established bytes-to-text boundary.
- E6 requires analogous treatment for `Card.fromstring`.
- E9 requires signature and callsite compatibility.

## Formal Domain

For the equivalence claims, input bytes are restricted to ASCII byte strings:

- `ascii(DATA)`
- `ascii(SEP)` when `sep` is bytes
- `ascii(IMAGE)`

This matches FITS header/card data's ASCII domain and the existing
`decode_ascii` helper. Non-ASCII bytes are handled by production code through
the existing warning/replacement behavior; that policy is recorded as
PO-8 rather than modeled as a successful exact-equivalence claim.

## Claims

The formal claims are written in `fvk/fits-fromstring-spec.k` over the fragment
semantics in `fvk/mini-python-fits.k`.

- H-BYTES-STRSEP: ASCII bytes header data with a text separator reaches
  `Header(DATA)` rather than `TypeError`.
- H-BYTES-BYTESEP: ASCII bytes header data with an ASCII bytes separator reaches
  `Header(DATA)` rather than mixed bytes/text failure.
- H-STR: text header data remains on the existing text parser path.
- C-BYTES: ASCII bytes card image reaches `Card(pad80(IMAGE))`.
- C-STR: text card image remains on the existing text card path.

## Frame Conditions

- No public method signatures change.
- Existing text input behavior is preserved because `decode_ascii(str)` is the
  identity.
- Existing binary file behavior is preserved because `Header._from_blocks`
  already decodes binary blocks before calling `Header.fromstring`.
