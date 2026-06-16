# Spec Audit

Status: constructed, not machine-checked.

| Claim | Intent coverage | Verdict |
| --- | --- | --- |
| C1 reverse many-to-one dispatch reaches `reverseFkEffect` | Matches I1 and I2. It is supported by E2, E4, and E5. | Pass |
| C2 many-to-many dispatch reaches `manyToManyEffect(op, through_defaults)` | Matches I1, I2, and I3. It is supported by E2, E4, E6, and E7. | Pass |
| C3 generic relation dispatch reaches `genericEffect` | Matches I4. The public issue hint did not name this file, but the manager is a relation-specific manager with the same copied-queryset proxy root cause and public sync behavior evidence. | Pass |
| C4 plain manager keeps queryset proxy behavior | Matches I5. It prevents a proof that only succeeds by changing global manager proxy behavior. | Pass |
| C5 async methods carry `alters_data = True` | Matches I6 and the public issue hint. | Pass |

No claim depends on preserving the buggy pre-fix behavior. No claim is derived
solely from V1 output; each claim is tied to the public issue, existing sync
related-manager contracts, or public in-repo tests.
