# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent coverage | Result |
| --- | --- | --- |
| `XYPoint` equality uses `Float.compare` and implies equal hashes. | Matches E1, E2, E6. | Pass |
| `XYCircle` equality uses `Float.compare` and implies equal hashes. | Matches E1, E3, E6. | Pass |
| `XYRectangle` is audited but unchanged. | Matches E3 and E4: source already uses `Float.compare` and bit-based hash. | Pass |
| `Point`, `Circle`, and `Rectangle2D` are included. | E5 plus Java's default equals/hash contract E6 justify broadening beyond V1. | Pass |
| Constructors, validation, hash formulas, and signatures are unchanged. | Matches frame condition in intent item 4. | Pass |
| Tests using primitive `==`/`!=` are not used as the expected-value oracle. | Matches intent item 5 and FVK suspect-test rule. | Pass |

No formal-English clause is weaker than the intent. The only broadened scope is the
same contract bug in adjacent geometry classes; that broadening is justified by E5
and PO-5 rather than by hidden tests or external knowledge.
