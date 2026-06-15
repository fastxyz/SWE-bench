# Public Evidence Ledger

Status: public/user-provided evidence only.

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`Header.fromstring` does not accept Python 3 bytes" | Python 3 bytes are in-domain for `Header.fromstring`; rejecting them is the reported bug. | Encoded in IS-2 and K claims H-BYTES-STRSEP/H-BYTES-BYTESEP. |
| E2 | `benchmark/PROBLEM.md` | Docs say `Header.fromstring` "creates an HDU header from a byte string containing the entire header data." | The public API contract names byte-string input, not text-only input. | Encoded in IS-2. |
| E3 | `benchmark/PROBLEM.md` | "it does work on Python 3's unicode `str`s" | Existing Python 3 `str` behavior should remain valid. | Encoded in IS-1/IS-3 and K claim H-STR. |
| E4 | `benchmark/PROBLEM.md` | "`Header.fromfile` will work with files opened in text or binary mode." | Direct bytes parsing should be consistent with binary file parsing. | Encoded in IS-7 and proof obligation PO-3. |
| E5 | `benchmark/PROBLEM.md` | "change `Header.fromstring` to accept unicode or bytes string types." | Both text and bytes are accepted input families for the same public method. | Encoded in IS-1/IS-2. |
| E6 | `benchmark/PROBLEM.md` | "`Card.fromstring` likely needs a similar treatment." | `Card.fromstring` has the same bytes boundary obligation as `Header.fromstring`. | Encoded in IS-5/IS-6 and K claim C-BYTES. |
| E7 | `repo/astropy/io/fits/header.py` | `Header.fromfile` reads binary blocks, calls `decode_ascii(block)`, joins text blocks, then calls `Header.fromstring(header_str, sep=sep)`. | `decode_ascii` is the established binary-header-to-text conversion boundary. | Encoded in PO-3 and PO-6. |
| E8 | `repo/astropy/io/fits/util.py` | `decode_ascii` decodes `bytes` as ASCII and warns/replaces non-ASCII bytes. | Reusing `decode_ascii` preserves the existing non-ASCII bytes policy instead of inventing a new one. | Encoded in IS-7 and PO-6. |
| E9 | Public callsites under `repo/astropy/io/fits` | Internal `Header.fromstring` and `Card.fromstring` callsites pass text strings after existing parsing/slicing. | The change must preserve text input and avoid signature or return-shape changes. | Encoded in IS-8 and compatibility audit. |

