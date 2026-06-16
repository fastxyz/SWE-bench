# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Low-precedence `Subs` body is grouped

Statement: For every substituted expression `expr` with
`precedence_traditional(expr) < PRECEDENCE["Mul"]`, `_print_Subs` renders
`\left(<latex(expr)>\right)` as the body inside the substitution bar.

Evidence: ledger E1-E3 and E6.

Formal claim: `PREC < 50` claim in `fvk/latex-subs-spec.k`.

Discharged by V1: yes. `parenthesize(expr, PRECEDENCE["Mul"], strict=True)`
wraps exactly when precedence is lower than the multiplication threshold.

## PO-002: Multiplication-precedence bodies are preserved

Statement: For every substituted expression `expr` with
`precedence_traditional(expr) >= PRECEDENCE["Mul"]`, `_print_Subs` does not add
new parentheses to the body.

Evidence: ledger E4 and E6.

Formal claim: `PREC >= 50` claim in `fvk/latex-subs-spec.k`.

Discharged by V1: yes. With `strict=True`, equality at multiplication
precedence is not wrapped, preserving the `Subs(x*y, ...)` public test shape.

## PO-003: The issue-shaped multiplication composes to the expected output

Statement: Rendering the product of coefficient `3` and
`Subs(-x + y, (x,), (1,))` yields
`3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`.

Evidence: ledger E2, E3, and E5.

Formal claim: issue-shaped claim in `fvk/latex-subs-spec.k`.

Discharged by V1: yes. `_print_Mul` prefixes the factor returned by
`_print_Subs`; the factor body is already grouped by PO-001.

## PO-004: Public printer compatibility is preserved

Statement: The patch must not change `LatexPrinter._print_Subs`'s signature,
return type, or substitution suffix formatting.

Evidence: intent item 5 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Formal representation: compatibility audit plus unchanged source shape.

Discharged by V1: yes. The edit changes only the expression assigned to
`latex_expr`.

## PO-005: Proof honesty

Statement: The proof must be labeled constructed, not machine-checked, and no
test deletion may be recommended as complete without running K tooling.

Evidence: FVK verify honesty gate.

Discharged by this FVK pass: yes. `fvk/PROOF.md` includes exact commands but
states that they were not run.
