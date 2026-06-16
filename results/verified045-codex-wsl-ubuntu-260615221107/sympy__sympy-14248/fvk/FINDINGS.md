# FVK Findings

Status: audit findings for V1. No tests or code were run.

## F-001: Reported MatrixSymbol Difference Printing Defect

Input: a `MatAdd` equivalent to negative `B`, negative `A*B`, and positive `A`,
as produced by the issue expression `A - A*B - B`.

Observed before V1: string output showed explicit `(-1)` matrix coefficients;
pretty output showed a literal plus before a negative matrix product; LaTeX
output showed `-1` as part of matrix term bodies.

Expected: negative matrix terms contribute subtraction signs to the surrounding
matrix-add rendering, and a unit negative coefficient is not printed as term
body text.

Classification: code bug in printer sign joining.

Status: resolved by V1. Discharged by `PO-SIGN`, `PO-NO-PLUS-NEG`,
`PO-NO-UNIT-COEFF`, `PO-STR`, `PO-LATEX`, and `PO-PRETTY`.

## F-002: All Issue-Named Printers Are In Scope

Input: the three user actions in the issue: `print(...)`, `pprint(...)`, and
`latex(...)`.

Observed before V1: each named printer had a separate matrix-add path that did
not fully implement scalar-add-style negative term handling.

Expected: all three named paths must satisfy the same sign discipline.

Classification: coverage obligation.

Status: resolved by V1. Discharged by `PO-COVERAGE`.

## F-003: Argument Ordering Is Underspecified

Input: any `MatAdd` where canonical argument order differs from the source
expression order.

Observed: `MatAdd` already owns argument ordering/canonicalization outside the
printer methods.

Expected: the issue requires subtraction-style rendering, not a new ordering
contract.

Classification: underspecified intent / frame condition.

Status: no code change. `PO-FRAME-ORDER` justifies preserving `expr.args` order.

## F-004: Explicit Matrix-Like Terms Without `as_coeff_mmul()`

Input: matrix-like arguments that do not expose `as_coeff_mmul()`.

Observed in V1: the printer treats these terms as coefficient-positive and
falls back to existing body rendering.

Expected: the issue concerns matrix-expression negative coefficients. There is
no public intent evidence requiring scalar coefficient extraction from
matrix-like objects that lack the matrix-expression API.

Classification: compatibility frame.

Status: no code change. `PO-DOMAIN` and `PO-FRAME-API` justify the fallback.

## F-005: Constructed Proof Not Machine-Checked

Input: the FVK formal artifacts and proof commands.

Observed: this environment forbids running Python, tests, or K tooling.

Expected: artifacts must include commands and reason about expected outcomes
without executing them.

Classification: proof honesty / residual risk.

Status: open operational caveat, not a code bug. `PROOF.md` labels the proof
constructed, not machine-checked.

## F-006: No Additional `_print_MatAdd` Contributors Found

Input: source search under `repo/sympy/printing` for `_print_MatAdd`.

Observed: the matrix-add printer contributors are the three issue-named
printers.

Expected: no untouched sibling matrix-add printer should keep producing the
reported defect for the issue-named behavior.

Classification: coverage confirmation.

Status: resolved by source inspection and `PO-COVERAGE`.
