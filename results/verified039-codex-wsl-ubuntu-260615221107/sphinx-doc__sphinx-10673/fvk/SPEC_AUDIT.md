# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
|---|---|---|
| `PARSE-GENINDEX`, `PARSE-MODINDEX`, `PARSE-SEARCH` | Matches E1/E2: the exact issue entries must be possible without nonexisting-document warnings. | Pass |
| `RESOLVE-GENINDEX`, `RESOLVE-MODINDEX`, `RESOLVE-SEARCH`, `RESOLVE-GENINDEX-EXPLICIT` | Matches E3/E5: generated entries reuse standard-domain labels, `modindex -> py-modindex`, and explicit toctree titles remain explicit. | Pass |
| `UNKNOWN-STILL-WARNS` | Matches E4 frame condition: only generated pages get special treatment; ordinary missing documents remain warnings. | Pass |
| `SOURCE-DOC-WINS` | Matches frame condition from existing toctree behavior: real documents remain documents. | Pass |
| `SECTION-SKIP-GENERATED`, `FIGURE-SKIP-GENERATED` | Matches E4/E6: generated pages are links, not source doctrees. | Pass |

No formal claim over-preserves the V1 implementation by relying solely on the
candidate behavior. The only V1-derived issue was the collector asymmetry in
section numbering; it is recorded in `FINDINGS.md` as fixed by V2.
