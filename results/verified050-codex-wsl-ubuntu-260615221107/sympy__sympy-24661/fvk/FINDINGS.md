# FVK Findings for sympy__sympy-24661

Status: constructed, not machine-checked. Findings are based on public intent
and static source inspection only.

## F1 - Resolved Code Bug: `<` Evaluated Despite `evaluate=False`

Input: `parse_expr('1 < 2', evaluate=False)`.

Observed pre-fix behavior from the public issue: `True`.

Expected behavior from public intent: `Lt(1, 2, evaluate=False)`, printed as
`1 < 2`.

V1 status: resolved. `EvaluateFalseTransformer.visit_Compare` now maps
`ast.Lt` to `Lt` and adds `evaluate=False` to the constructed call.

Proof links: PO1 and PO4.

## F2 - Resolved Delegation Bug: `sympify` String Path

Input: `sympify('1 < 2', evaluate=False)`.

Observed pre-fix behavior from the public issue: `True`.

Expected behavior from public intent: the same unevaluated relational as the
parser path.

V1 status: resolved by the parser fix. `sympify` passes the `evaluate` argument
to `parse_expr` for string input, so no separate `sympify` edit is justified.

Proof links: PO5.

## F3 - Resolved Family Coverage: Standard Python Comparison Operators

Input family: `==`, `!=`, `<`, `<=`, `>`, `>=` in `parse_expr(...,
evaluate=False)`.

Observed pre-fix behavior: comparison AST nodes were not handled by
`EvaluateFalseTransformer`, so Python comparison semantics could evaluate them
instead of preserving relationals.

Expected behavior: use the corresponding SymPy relational constructor with
`evaluate=False`.

V1 status: resolved for the standard `ast.Compare` operator classes through the
`relational_operators` map.

Proof links: PO1, PO2, and PO3.

## F4 - Resolved Family Coverage: Chained Comparisons

Input family: chained comparison syntax such as `1 < 2 < 3` under
`evaluate=False`.

Observed pre-fix behavior: chained comparisons are represented by one
`ast.Compare` node and would fall back to Python comparison-chain truth
evaluation.

Expected behavior under the comparison-node family contract: preserve the
pairwise relationals rather than truth-evaluating the chain.

V1 status: resolved by producing `And(pairwise_relationals, evaluate=False)`.

Residual assumption: the parser contract is mathematical-expression oriented;
the proof does not claim preservation of Python side-effect evaluation counts
for custom callables embedded as middle operands of a chain. This is not part of
the public issue intent and does not block the repair.

Proof links: PO2.

## F5 - Non-Blocking Scope Decision: Explicit Relational Constructor Calls

Input family considered: explicit calls such as `parse_expr('Lt(1, 2)',
evaluate=False)` or optional transformations that already produce an `Eq(...)`
call before `evaluateFalse`.

Observed V1 behavior: V1 does not add relation constructor names to the existing
`visit_Call` evaluate-false whitelist.

Decision: leave V1 unchanged. The public issue localizes the bug to Python
comparison syntax represented by `ast.Compare`, and direct users already have
an explicit constructor form, e.g. `Lt(1, 2, evaluate=False)`. Broadening the
name-based call whitelist could alter behavior for local dictionaries that
shadow names such as `Eq` or `Lt`; that broader compatibility change is not
required to discharge the issue's intent.

Proof links: PO6.

## F6 - Honesty Gate: Proof Not Machine-Checked

No `kompile`, `kast`, `kprove`, Python import, or test command was run. The
proof is constructed from source inspection and public intent only.

Decision: keep tests until a real execution environment can run the project's
tests and, if desired, the emitted FVK commands.

Proof links: PO7.

