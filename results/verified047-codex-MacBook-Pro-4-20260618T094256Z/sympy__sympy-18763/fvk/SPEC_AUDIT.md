# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent comparison | Result |
|---|---|---|
| Additive expression in the issue example is parenthesized inside the `Subs` bar. | Directly matches the desired output in `benchmark/PROBLEM.md`. | PASS |
| Reported legacy raw additive shape is modeled only as diagnostic. | Directly matches the problem statement's bad output and is marked SUSPECT, not expected. | PASS |
| Substitution assignment suffix is preserved. | Desired output changes only the grouping of `- x + y`; the suffix remains `x=1`. | PASS |
| Non-additive multiplicative `Subs` expression is not parenthesized. | Matches the existing public in-repo LaTeX expectation for `Subs(x*y, ...)`. | PASS |
| Strict parenthesizing leaves `Mul`-precedence and stronger expressions unchanged. | Required to satisfy the non-additive frame condition and follows the local printer's strict parenthesize convention. | PASS |
| The proof is limited to the modeled LaTeX printer fragment. | The problem concerns `Subs` LaTeX shape, not full SymPy evaluation or every printer method. | PASS |

No required behavior is marked FAIL or AMBIGUOUS.

## Adequacy conclusion

The formal English matches the intent spec for the audited fragment. The proof
package is therefore adequate to audit whether V1's `parenthesize(...,
PRECEDENCE["Mul"], strict=True)` strategy satisfies the public issue and the
non-additive frame condition, subject to the explicit "constructed, not
machine-checked" caveat.
