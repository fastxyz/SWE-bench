# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "pprint unicode does not format subscripts on Greek letters" | Fix unicode pretty output for Greek-letter trailing digits. |
| I2 | `benchmark/PROBLEM.md` | `sp.pprint(w) # -> [w₀, ...]`; `sp.pprint(ω) # -> [ω0, ...]` | Greek examples should match Latin examples. |
| I3 | `benchmark/PROBLEM.md` | `[a-zA-Z]` should become Unicode-word matching | The base matcher must admit non-ASCII word characters. |
| I4 | public tests | `beta12`, `Y00`, `q21` suffix expectations | Preserve ASCII multi-digit suffix behavior. |
| I5 | public tests | `x_a_b`, `x_1^aa`, `alpha_11_11` expectations | Preserve explicit sub/sup separator parsing. |
| I6 | source | `pretty_symbol` consumes `split_super_sub` and the digit `sub` table | Helper split is sufficient for unicode pretty output to render digit subscripts. |
