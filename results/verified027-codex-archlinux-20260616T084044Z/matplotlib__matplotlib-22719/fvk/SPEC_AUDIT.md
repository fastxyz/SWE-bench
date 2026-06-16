# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent coverage | Result |
| --- | --- | --- |
| `CONVERT-EMPTY-VACUOUS-NUMERIC` | Matches I1-I3 and E1-E5. It does not preserve the SUSPECT legacy warning in E2. | Pass |
| `CONVERT-NONEMPTY-NUMERIC` | Matches I4 and E7; preserves public-test behavior for non-empty numeric values. | Pass |
| `CONVERT-NONEMPTY-CATEGORICAL` | Matches I5 and E9 at the warning/result-size level. Full mapping order is intentionally outside this proof and remains test-covered. | Pass with scoped residual risk |
| `CONVERT-NONEMPTY-INVALID` | Matches I5 and E8; preserves non-empty mixed-type rejection. | Pass |
| `UPDATE-EMPTY-CONVERTIBLE` | Matches I6 and E6; prevents empty-data vacuity from emitting the log. | Pass |
| `UPDATE-NONEMPTY-CONVERTIBLE` | Matches I6 and preserves non-empty logging behavior. | Pass |

## Adequacy conclusion

The K claims say no weaker property than the public empty-data intent for the
changed warning/log branches. They also avoid over-preserving the reported
legacy bug: the pre-fix empty-data deprecation warning is explicitly marked
SUSPECT and is not encoded as intended behavior.

The proof does not claim to verify full NumPy array construction, full mapping
order, date parsing, or artist integration. Those are frame-preserved by the
source edit and should remain covered by public and hidden tests.
