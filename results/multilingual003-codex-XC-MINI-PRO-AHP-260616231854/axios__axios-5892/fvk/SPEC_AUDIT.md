# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent clause | Result | Notes |
|---|---|---|---|
| C-DECOMPRESS-FALSE | Intent 3 | Pass | Existing behavior is a frame condition. |
| C-ABSENT | Intent 5 | Pass | No public intent asks to create a header or decoder when absent. |
| C-HEAD | Intent 4 | Pass | Existing no-body behavior is preserved. |
| C-204 | Intent 4 | Pass | Existing no-body behavior is preserved. |
| C-GZIP | Intent 1, 2, 5 | Pass | Directly addresses the reported bug family. |
| C-DEFLATE | Intent 1, 5 | Pass | Generalizes case-insensitive comparison uniformly across existing supported encodings. |
| C-BR-SUPPORTED | Intent 1, 5 | Pass | Generalizes case-insensitive comparison while preserving Brotli support guard. |
| C-BR-UNSUPPORTED | Intent 5 | Pass | Preserves existing `isBrotliSupported` condition. |
| C-UNKNOWN | Intent 5 | Pass | No public intent asks to decode unknown encodings. |
| C-NORM | Intent 1, 7 | Pass | Lowercase comes from the issue; trim comes from the token default-domain assumption. |
| Stacked encodings omitted | None explicit | Ambiguous, not a failure | Recorded as F4 and excluded from this proof. |
