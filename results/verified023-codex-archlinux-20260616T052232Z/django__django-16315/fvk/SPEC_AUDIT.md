# SPEC_AUDIT

Status: adequacy audit for the constructed claims.

| Claim | Intent coverage | Result |
| --- | --- | --- |
| C1 | Matches I1, I3, and I5: the upsert path must recover field metadata from model field names. | Pass |
| C2 | Matches I1, I2, I3, and I5: conflict targets must recover field metadata before SQL generation. | Pass |
| C3 | Matches I2, I3, and I4: SQL identifiers must be `Field.column` values. | Pass |
| C4 | Matches I6: the issue and docs bind the conversion to update conflicts, not unrelated inserts. | Pass |
| C5 | Matches I7: backend hooks quote identifier strings and should receive database columns. | Pass |

No claim is candidate-only, legacy-derived, or stronger than the public issue
requires. The V1-specific generator and non-upsert conversion behaviors were
not accepted as spec; they were recorded as findings and repaired in V2.
