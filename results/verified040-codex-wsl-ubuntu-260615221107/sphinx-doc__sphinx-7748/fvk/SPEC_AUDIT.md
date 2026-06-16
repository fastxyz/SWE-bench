# Specification Adequacy Audit

| Formal item | Intent item | Result | Notes |
|---|---|---|---|
| FIND-TWO | Intent 1-4 | pass | Captures multiple leading overload signatures and body stripping. |
| FIND-THREE-PREFIX | Intent 1-4 | pass | Confirms family/cardinality behavior beyond a two-line example. |
| FIND-STOPS-AT-PROSE | Intent 6-7 | pass | Leading-only scope is derived from issue text and existing docs. |
| FIND-NO-MATCH | Intent 6 | pass | Preserves existing signature validity rules. |
| FIND-SINGLE-COMPAT | Intent 5 | pass | Single-signature behavior remains intact. |
| FORMAT-SINGLE | Intent 5 | pass | Single formatting shape remains intact. |
| FORMAT-TWO | Intent 2-3 | pass | Newline formatting preserves all overload signatures in order. |
| STRIP-WRAPPER-NO-REEMIT | Intent 9 | pass | Public compatibility consumer remains safe. |
| FORMAT-EXPLICIT-BYPASS | Intent 8 | pass | Explicit directive signatures still win. |

No formal item is marked fail or ambiguous.  The docs wording noted in F-05 is a
documentation follow-up, not a mismatch between the formal spec and public
intent.
