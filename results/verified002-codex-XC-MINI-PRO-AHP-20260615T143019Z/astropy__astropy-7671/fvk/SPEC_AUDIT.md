# Spec Audit

Status: adequacy audit comparing `FORMAL_SPEC_ENGLISH.md` to
`INTENT_SPEC.md`.

| Formal item | Intent match | Result |
|---|---|---|
| C1 reported case returns `True` | Matches intent items 1 and 2. | Pass |
| C2 inclusive mode compares normalized numeric prefixes with `>=` | Matches intent items 3 and 4. | Pass |
| C3 exclusive mode compares normalized numeric prefixes with `>` | Matches intent item 4. | Pass |
| C4 missing import returns `False` | Matches intent item 5. | Pass |
| C5 invalid module raises `ValueError` | Matches intent item 5. | Pass |
| S1 numeric-prefix domain | Matches intent item 6 and public evidence E7. | Pass |

No formal claim over-preserves legacy buggy behavior. The only explicit boundary
is full package-version parsing, which the public issue does not require.

