# FVK Findings

Status: constructed from public evidence and source audit. No tests, Python, or
K tooling were run.

## Findings

### F-001: Pre-fix code bug, resolved by V1

Input: `latex(3*Subs(-x + y, (x,), (1,)))`

Observed pre-fix behavior from the issue:
`3 \left. - x + y \right|_{\substack{ x=1 }}`

Expected behavior from the issue:
`3 \left. \left(- x + y\right) \right|_{\substack{ x=1 }}`

Classification: code bug in LaTeX rendering.

Trace:

- Ledger E1-E3.
- Proof obligation PO-001.
- K issue-shaped claim in `fvk/latex-subs-spec.k`.

Resolution: V1 changes `_print_Subs` to call
`self.parenthesize(expr, PRECEDENCE["Mul"], strict=True)`, so additive
precedence bodies are grouped inside the substitution bar.

### F-002: Frame condition for `Subs(x*y, ...)`, discharged by V1

Input: `latex(Subs(x*y, (x, y), (1, 2)))`

Observed intended public behavior from the in-repo latex test:
`\left. x y \right|_{\substack{ x=1\\ y=2 }}`

Expected behavior after V1: unchanged.

Classification: compatibility/frame condition.

Trace:

- Ledger E4.
- Proof obligation PO-002.
- K `PREC >= 50` claim in `fvk/latex-subs-spec.k`.

Resolution: `strict=True` only wraps when the expression precedence is strictly
lower than multiplication, so multiplication-precedence bodies are not wrapped.

### F-003: No residual source defect found within the public intent

Input class: `Subs(expr, old, new)` where `expr` has lower precedence than
multiplication and is used as a multiplicative factor.

Observed V1 behavior by source reasoning: `_print_Subs` groups the body before
the factor is composed by `_print_Mul`.

Expected behavior: grouped body inside the substitution bar.

Classification: no code bug found in the audited scope.

Trace:

- Ledger E3, E5, E6.
- Proof obligations PO-001 and PO-003.
- Spec audit pass entries in `fvk/SPEC_AUDIT.md`.

Decision: V1 stands unchanged.

## Proof-Derived Findings

No proof obstacle required a new source change. The constructed proof introduces
one explicit frame obligation, PO-002, to prevent the additive fix from changing
the public `Subs(x*y, ...)` output. V1 discharges that obligation by using
`strict=True`.

Residual risk: the proof is constructed, not machine-checked. Test removal is
not recommended until the emitted `kompile` and `kprove` commands are actually
run in an environment that supports K.
