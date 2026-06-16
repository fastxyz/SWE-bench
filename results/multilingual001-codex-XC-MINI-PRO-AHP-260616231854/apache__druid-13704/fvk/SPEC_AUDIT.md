# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| LOOKUP-POW | Matches intent item 1 and evidence E1. | Pass |
| POW-PAIR | Matches intent item 2 and evidence E2. | Pass |
| POW-FOLD-TWO | Matches intent items 2 and 3. | Pass |
| POW-FOLD-THREE | Matches intent item 4 and evidence E4. | Pass |
| POW-NULL | Matches intent item 4 and evidence E7. | Pass |
| POW-CACHE-ORDER | Matches intent item 5 and evidence E8. | Pass |

## Ambiguity Audit

The prompt's later `power(f1,3)` wording is ambiguous, but it is outweighed by the title/proposal `pow`, existing expression docs `pow(x, y)`, and SQL conversion to `"pow"`. The formal spec intentionally does not prove or require a `power` alias.

No formal claim is derived solely from V1 behavior. Each claim has public intent, existing documentation, or cache-correctness evidence.
