# Spec Audit

Status: constructed for audit; not machine-checked.

| Formal English Item | Intent Match | Result |
|---|---|---|
| `CLAIM-ALIGN-GENERAL` assigns defaults over `posonlyargs + args`. | Matches I1 and default-domain evidence E4. | Pass |
| `CLAIM-ISSUE-EXAMPLE` gives `b` default `0` for `(a, b=0, /, c=1)`. | Directly matches I1, I2, and issue example E2. | Pass |
| `CLAIM-NO-POSONLY-REGRESSION` preserves no-posonly default behavior. | Matches I3 and visible public-test evidence E5. | Pass |
| `CLAIM-RENDERING` shows defaults when `Parameter.default` is not empty. | Matches I1 and I3; supported by code evidence E6. | Pass |
| `FRAME-OTHER-PARAMETER-FORMS` leaves unrelated parsing and rendering behavior unchanged. | Matches I3 and I5. | Pass |

No formal-English item is weaker than the intent. No item relies solely on the
V1 implementation as the expected behavior; the alignment rule is independently
supported by the issue and by Python AST/default-domain evidence mirrored in
Sphinx's existing AST unparser.
