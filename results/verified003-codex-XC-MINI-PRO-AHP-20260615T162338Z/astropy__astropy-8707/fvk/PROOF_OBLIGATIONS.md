# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Header Bytes Data Normalization

For any ASCII byte string `DATA`, `Header.fromstring(DATA, sep)` must normalize
`DATA` to text before card splitting, comparison with text sentinels, or joining
card fragments.

Evidence: E1, E2, E5. Formal claims: H-BYTES-STRSEP, H-BYTES-BYTESEP.

Status: discharged by V1. `Header.fromstring` calls `decode_ascii(data)` before
the splitting loop.

## PO-2: Header Separator Normalization

If `sep` is provided as bytes, it must be normalized to text before
`set(sep)`, `len(sep)`, `data.index(sep, idx)`, and `next_image.split(sep)`.

Evidence: IS-4, E4. Formal claim: H-BYTES-BYTESEP.

Status: discharged by V1. `Header.fromstring` calls `decode_ascii(sep)` before
separator-sensitive logic.

## PO-3: Consistency With Binary File Reading

Direct bytes input should use the same ASCII conversion boundary as
`Header.fromfile`/`Header._from_blocks`.

Evidence: E4, E7, E8. Formal claims: H-BYTES-STRSEP, H-BYTES-BYTESEP.

Status: discharged by V1. It reuses `decode_ascii`, the helper already used by
`Header._from_blocks`.

## PO-4: Preserve Header Text Behavior

For text input, the added normalization must be the identity and the existing
text parser path must remain unchanged.

Evidence: E3, E9. Formal claim: H-STR.

Status: discharged by V1. `decode_ascii(str)` returns the original `str`.

## PO-5: Card Bytes Image Normalization

For any ASCII byte string `IMAGE`, `Card.fromstring(IMAGE)` must normalize
`IMAGE` to text before `_pad` and before later text-regex parsing.

Evidence: E6, E8. Formal claim: C-BYTES.

Status: discharged by V1. `Card.fromstring` calls `decode_ascii(image)` before
`_pad(image)`.

## PO-6: Preserve Card Text Behavior

For text card images, the added normalization must be the identity and the
existing padding/lazy parsing behavior must remain unchanged.

Evidence: E5, E9. Formal claim: C-STR.

Status: discharged by V1. `decode_ascii(str)` returns the original `str`.

## PO-7: Public Compatibility

The fix must not change public signatures, return types, or existing text
callsite behavior.

Evidence: E9 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged. No signature or return shape changed; the accepted input
domain was expanded.

## PO-8: Non-ASCII Bytes Boundary

Exact bytes/text equivalence is required only for ASCII FITS header/card bytes.
Non-ASCII bytes should not introduce a new policy inconsistent with binary
file reading.

Evidence: E7, E8. Formal boundary: B-NONASCII.

Status: discharged by reuse of `decode_ascii`. The K equivalence claims are
intentionally guarded with `ascii(...)`.

## PO-9: FVK Honesty Gate

The FVK proof must be labeled as constructed, not machine-checked, because this
benchmark forbids executing K tooling.

Evidence: task no-exec instruction and FVK verify honesty gate.

Status: discharged in `fvk/PROOF.md`, `fvk/FINDINGS.md` F5, and
`fvk/ITERATION_GUIDANCE.md`. No test deletion is recommended.
