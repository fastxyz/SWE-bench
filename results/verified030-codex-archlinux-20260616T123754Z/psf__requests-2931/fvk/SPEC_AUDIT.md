# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict | Notes |
| --- | --- | --- | --- |
| CLAIM-ENCODE-BYTES | I1, I2 | PASS | Bytes are preserved before any body preparation call can decode them. |
| CLAIM-PREPARE-BODY-BYTES | I1, I2, I4 | PASS | Matches the issue reproduction class: non-empty raw bytes body, no files. |
| CLAIM-PREPARE-URL-BYTES | I5 | PASS | Preserves the public `params=b"test=foo"` behavior after `_encode_params` stops decoding bytes. |
| CLAIM-PREPARE-BODY-FORM | I3 | PASS | Preserves documented and public-test form encoding. |
| Empty bytes with `json` | D1 | OUT OF SCOPE | Existing truthiness behavior is not the reported regression and is not used to justify V2. |
| Multipart, stream, file-like branches | D3 | OUT OF SCOPE FRAME | V2 does not alter those branches. |

No claim is candidate-only or legacy-only. The only public-test-derived frame
conditions are consistent with the issue intent.
