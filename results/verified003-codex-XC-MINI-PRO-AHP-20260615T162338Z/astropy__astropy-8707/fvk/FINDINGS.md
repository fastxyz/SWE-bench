# Findings

Status: FVK audit findings for V1.

## F1: Header.fromstring Bytes Rejection

Input: `Header.fromstring(Bytes(DATA), Str(""))` where `DATA` is ASCII FITS
header bytes.

Observed before V1: bytes slices flowed into text comparisons and
`''.join(...)`, producing mixed bytes/text behavior instead of a parsed header.

Expected: bytes data decodes as ASCII and reaches the same text parser path as
`Header.fromstring(Str(DATA), Str(""))`.

Evidence: E1, E2, E5. Proof obligations: PO-1, PO-3, PO-4.

Classification: code bug, resolved by V1.

Resolution: keep the V1 `decode_ascii(data)` normalization in
`Header.fromstring`.

## F2: Header.fromstring Bytes Separator Mixed-Type Path

Input: `Header.fromstring(Bytes(DATA), Bytes(SEP))` where `DATA` and `SEP` are
ASCII bytes.

Observed before V1: separator operations could mix bytes data with text parser
logic, or compare bytes fragments against text sentinels.

Expected: bytes separator decodes to the equivalent text separator before
splitting.

Evidence: IS-4, E4. Proof obligations: PO-2, PO-3.

Classification: compatibility edge case, resolved by V1.

Resolution: keep the V1 `decode_ascii(sep)` normalization in
`Header.fromstring`.

## F3: Card.fromstring Bytes Rejection

Input: `Card.fromstring(Bytes(IMAGE))` where `IMAGE` is ASCII card-image bytes.

Observed before V1: `_pad` and later card parsing received a bytes image even
though padding and parser regular expressions are text-oriented.

Expected: bytes image decodes as ASCII and reaches the same padding/text parser
path as `Card.fromstring(Str(IMAGE))`.

Evidence: E6, E8. Proof obligations: PO-5, PO-6.

Classification: code bug, resolved by V1.

Resolution: keep the V1 `decode_ascii(image)` normalization in
`Card.fromstring`.

## F4: Public Compatibility

Input family: existing public/internal calls using `str` header/card images.

Observed after V1 by source inspection: signatures are unchanged and
`decode_ascii(str)` is identity.

Expected: existing text behavior remains unchanged.

Evidence: E3, E9. Proof obligation: PO-7.

Classification: compatibility check, passed.

Resolution: no additional source change.

## F5: Machine-Checking Not Performed

Input: formal claims in `fits-fromstring-spec.k`.

Observed: the proof is constructed only; `kompile`, `kast`, and `kprove` were
not run because this benchmark forbids executing K tooling.

Expected: a future machine check should return `#Top` for the listed claims.

Evidence: task no-exec instruction and FVK honesty gate.

Classification: verification limitation, not a code bug.

Resolution: keep tests; do not remove any test based on this constructed proof.

## Open Code Findings

None. The FVK audit found no uncovered public-intent obligation requiring a V2
source edit beyond V1.

