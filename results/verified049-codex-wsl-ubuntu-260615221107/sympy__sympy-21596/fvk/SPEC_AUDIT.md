# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| C1 reported real intersection is `FiniteSet(-1, 1)` | E3, E4 | PASS | Matches the issue's correct output and the zero-imaginary equation. |
| C2 `2` is not in the real intersection | E1, E2 | PASS | Directly matches the issue's corrected membership result. |
| C3 `-1` and `1` are in the result | E3, E4 | PASS | Required by exact finite result `{-1, 1}`. |
| C4 denominator roots are excluded | E5 | PASS | Preserves issue #19513 compatibility and avoids proving `1/n` image subset of reals. |
| Legacy complement expected by public test | E6 | SUSPECT, REJECTED | This conflicts with prompt intent and is not a valid postcondition. |
| No public API/signature change | source diff | PASS | The change is internal to the dispatched handler body. |

No required behavior is marked fail or ambiguous. The proof remains constructed,
not machine-checked.

