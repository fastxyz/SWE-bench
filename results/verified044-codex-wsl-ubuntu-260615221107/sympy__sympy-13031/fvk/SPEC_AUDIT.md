# Spec Audit

Status: pass. The formal claims match the intent spec for the shape behavior
under audit.

| Formal claim | Intent coverage | Result |
| --- | --- | --- |
| `ROW-JOIN-ZERO-COL` | Matches E4 and required behavior 5. | Pass |
| `ROW-JOIN-COMPAT` | Matches required behavior 3. | Pass |
| `ROW-JOIN-ERROR` | Matches existing public shape compatibility rule outside the null-column adaptation. | Pass |
| `COL-JOIN-ZERO-ROW` | Matches E4 and required behavior 5. | Pass |
| `COL-JOIN-COMPAT` | Matches required behavior 4. | Pass |
| `COL-JOIN-ERROR` | Matches existing public shape compatibility rule outside the null-row adaptation. | Pass |
| `HSTACK-ZERO-ROWS-FOUR` | Directly matches E1 and E2. | Pass |
| `VSTACK-ZERO-COLS-FOUR` | Directly matches E3 and issue hint family. | Pass |
| `HSTACK-COMPAT-NONEMPTY-FOUR` | Matches the issue's nonempty-row contrast example. | Pass |
| `VSTACK-COMPAT-NONEMPTY-FOUR` | Matches the vertical family implied by E3 and common matrix contract. | Pass |

## Adequacy Notes

- The model keeps the property under test: matrix shape. A failing V1
  predecessor maps `hstack(0x0, 0x1, 0x2, 0x3)` to `0x3`; the V1 model maps it
  to `0x6`, so the abstraction distinguishes the defect.
- The model intentionally omits sparse entry maps. That omission is not
  property-erasing for this issue because every relevant public output has no
  entries and is asserted through shape.
- No ordered-entry, winner, or precedence behavior is used to justify V1.
