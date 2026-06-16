# Public Evidence Ledger

| ID | Source | Quote or observation | Obligation |
| --- | --- | --- | --- |
| IE-1 | `benchmark/PROBLEM.md` | "Morse encoding for \"1\" is not correct" | Correct default encode output for `"1"`. |
| IE-2 | `benchmark/PROBLEM.md` | "incorrect mapping of `\"----\": \"1\"`; The correct mapping is `\".----\": \"1\"`" | Replace the source table key for digit `1`. |
| IE-3 | `repo/sympy/crypto/crypto.py` | `char_morse = {v: k for k, v in morse_char.items()}` | The encode table is derived from the decode table. |
| IE-4 | `repo/sympy/crypto/tests/test_crypto.py` | Public tests cover Morse letters, whitespace, punctuation, and invalid decode input. | Preserve existing behavior; note missing digit-1 coverage. |
| IE-5 | default-domain assumption | Standard Morse digit family. | Check all digit entries for a table-family repair. |

