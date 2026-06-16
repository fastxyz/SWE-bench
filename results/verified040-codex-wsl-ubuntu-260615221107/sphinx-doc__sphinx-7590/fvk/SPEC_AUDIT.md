# Spec Audit

Status: adequacy gate for the constructed claims.

| Formal claim | Intent source | Verdict | Notes |
| --- | --- | --- | --- |
| UDL-NUMERIC | E1, E2, E3 | pass | Directly covers the reported failure. |
| UDL-STRING | E1, E3, E5 | pass | Covers the C++ UDL family beyond numeric literals. |
| UDL-CHAR | E1, E3, E5 | pass | Covers character literal suffixes without changing `ASTCharLiteral` decoding. |
| NO-SUFFIX-FRAME | E4, existing parser behavior | pass | Preserves ordinary literal parsing when no immediate suffix exists. |
| FRAME | E4, E6 | pass | Keeps operator declarations and C-domain behavior out of the source change. |

## Ambiguities

- The public issue does not discuss universal-character-name suffix spelling.
  The spec intentionally follows the existing parser's ASCII identifier scope.
- The public issue does not require full C++ lexical validation of raw string
  delimiters. The implementation scans raw string bodies well enough to preserve
  the literal token and attach a suffix, but it does not validate every delimiter
  restriction from the C++ standard.

Neither ambiguity is used to justify accepting a known in-domain failure for the
reported numeric case or the ordinary/prefixed/raw string and character suffix
cases modeled here.
