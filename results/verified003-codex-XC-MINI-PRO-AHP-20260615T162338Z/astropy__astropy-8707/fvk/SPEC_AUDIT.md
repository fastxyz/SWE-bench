# Spec Audit

Status: adequacy gate for `FORMAL_SPEC_ENGLISH.md` against `INTENT_SPEC.md`.

| Formal item | Intent item(s) | Audit | Notes |
| --- | --- | --- | --- |
| H-BYTES-STRSEP | IS-2, IS-7 | Pass | Captures the core reported defect for `Header.fromstring` bytes data. |
| H-BYTES-BYTESEP | IS-2, IS-4, IS-7 | Pass | Extends the same normalization rule to byte separators so the method avoids mixed bytes/text operations. |
| H-STR | IS-1, IS-3 | Pass | `decode_ascii` is identity on `str`, so existing text behavior is preserved. |
| C-BYTES | IS-6, IS-7 | Pass | Captures the analogous `Card.fromstring` bytes treatment requested by the issue. |
| C-STR | IS-5 | Pass | Preserves existing text card parsing behavior. |
| F-SIGNATURE | IS-8 | Pass | V1 changes accepted input types only; public call signatures are unchanged. |
| B-NONASCII | IS-7 | Pass | Public intent is ASCII FITS header/card bytes. Existing non-ASCII handling is preserved through `decode_ascii`. |

No formal item is marked fail or ambiguous. The proof can justify leaving V1
unchanged if all proof obligations discharge under these claims.

