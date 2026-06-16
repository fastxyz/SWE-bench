# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| `PRE_FIX_COUNTEREXAMPLE` | I-001, I-003 | Pass | It symbolically reproduces the issue's described length-two failure mechanism. |
| `PRECEDING_V1_SAFE` | I-001, I-002, I-003 | Pass | It proves the lower-middle seed prevents the described out-of-bounds access across all positive lengths, including `N = 2`. |
| `MOVE_SAFE` | I-001 | Pass | It captures the helper invariant needed to make `currentSentence + 1` safe in every non-base frame. |
| Public compatibility frame | I-004 | Pass | The source change is a one-expression change inside an existing method body; no public or protected contract shape changed. |
| Concrete return offsets | I-004 | Ambiguous but non-blocking | The K model intentionally abstracts return values because the issue intent concerns the exception and midpoint. Existing source behavior and public local tests are preserved by the one-expression edit. |

No formal item contradicts the public problem statement. No item relies on hidden tests,
upstream patches, benchmark outcomes, or internet material.
