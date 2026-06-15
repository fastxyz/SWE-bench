# FVK Notes

## Decision Summary

V1 stands unchanged after the FVK audit.

## Trace To Findings And Obligations

Decision D1: keep `Header.fromstring` decoding `data` with `decode_ascii`.

- Trace: `fvk/FINDINGS.md` F1.
- Obligations: `fvk/PROOF_OBLIGATIONS.md` PO-1, PO-3, PO-4.
- Reason: the public issue requires Python 3 bytes data to reach the same
  parser as text data. V1 normalizes before the splitting loop, eliminating the
  mixed bytes/text failure.

Decision D2: keep `Header.fromstring` decoding `sep` with `decode_ascii`.

- Trace: `fvk/FINDINGS.md` F2.
- Obligations: PO-2, PO-3.
- Reason: although the issue focuses on header data, separator operations are
  part of the same text-splitting boundary. Normalizing `sep` avoids a
  remaining mixed bytes/text edge case and preserves text separators because
  `decode_ascii(str)` is identity.

Decision D3: keep `Card.fromstring` decoding `image` with `decode_ascii`.

- Trace: `fvk/FINDINGS.md` F3.
- Obligations: PO-5, PO-6.
- Reason: card padding and later regex parsing are text-oriented. Decoding bytes
  before `_pad` makes bytes card images equivalent to text card images in the
  ASCII domain required by the issue.

Decision D4: make no additional compatibility edits.

- Trace: `fvk/FINDINGS.md` F4 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Obligation: PO-7.
- Reason: no public signatures or return shapes changed, and inspected
  callsites continue to pass through the same text parser path.

Decision D5: do not edit tests and do not claim machine verification.

- Trace: `fvk/FINDINGS.md` F5 and `fvk/PROOF.md`.
- Obligation: PO-9.
- Reason: the task forbids test edits and forbids executing tests, Python, or K
  tooling. The proof is therefore labeled constructed, not machine-checked, and
  no test removal is recommended.

## Source Changes During FVK

None. The audit found no open code finding requiring a V2 source edit beyond
the V1 fix.
