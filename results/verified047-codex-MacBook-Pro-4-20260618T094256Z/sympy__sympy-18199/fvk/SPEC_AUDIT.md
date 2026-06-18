# Spec Audit

Status: constructed, not machine-checked.

| Formal English Item | Intent Match | Audit |
|---|---|---|
| Zero scalar returns `0` for positive `N != 2`, positive prime `P`, and `A % P == 0` | Pass | Directly matches the issue and docstring. |
| Zero list returns `[0]` for the same prime zero-residue class | Pass | The issue requires zero not be omitted; the docstring says `all_roots=True` returns the list of roots; prime-field uniqueness makes the list singleton. |
| Negative multiples of `P` are covered by the zero-residue claims | Pass | Public docs say `a` is an integer and issue states the condition as `a % p == 0`; V1's `a >= 0` dependency was implementation-derived. |
| `n == 2` delegates to `sqrt_mod` | Pass | Existing source and behavior are preserved; the issue concerns `nthroot_mod` for a fifth root, not square-root internals. |
| Composite moduli remain not implemented for `n > 2` | Pass | Existing source and public tests support the not-implemented behavior; implementing composite roots is outside the public zero-root intent. |
| Nonresidue returns `None` | Pass | Existing public behavior and tests support this branch; the zero-root issue does not contradict it. |
| Nonzero prime residues use the existing solver | Pass | This is a compatibility frame condition; no public evidence requires changing this path. |
| Prime-zero uniqueness theorem | Pass for adequacy; escalation-bounded for machine proof | The theorem matches the mathematical intent. The mini K theory does not prove prime divisibility internally, so this is a proof capability boundary, not a code counterexample. |

No formal-English obligation contradicts public intent. The audit did find that V1 did not meet the negative-multiple member of the zero-residue family; that is recorded as a Finding and drives the V2 source edit.
