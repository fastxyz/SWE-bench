# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Claim | Intent coverage | Result |
| --- | --- | --- |
| C1 | Covers intent items 1, 2, and 3: prefixes with regex metacharacters are literal field-name components. | PASS |
| C2 | Covers intent item 2: selected values are exactly those belonging to generated primary-key field names. | PASS |
| C3 | Covers intent item 4: existing returned order is preserved. | PASS |
| C4 | Covers intent item 4: compatibility and caller protocol are preserved. | PASS |

No claim is derived solely from legacy buggy behavior. The model's abstraction of
regex semantics is limited to the issue-relevant property: escaped dynamic
fragments match literally.

