# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Incorrect parenthesizing of Subs" | The defect is in how `Subs` LaTeX grouping is rendered. | Encoded in S1 and PO-001. |
| E2 | prompt | `3*Subs(-x+y, (x,),(1,))` currently prints `3 \left. - x + y \right|...` | The ungrouped additive body is the observed buggy behavior. | Recorded as F-001. |
| E3 | prompt | "It would be better to be parenthesized to: `3 \left. \left(- x + y\right) \right|...`" | The expected output groups the `Subs` body itself, before the substitution bar closes. | Encoded in K claim ISSUE-ADD-SUBS shape and PO-001. |
| E4 | public-test | `latex(Subs(x*y, (x, y), (1, 2))) == r'\left. x y \right|_{\substack{ x=1\\ y=2 }}'` | Multiplication-precedence bodies should remain unwrapped. | Encoded in PO-002. |
| E5 | implementation | `_print_Mul` renders each factor through `self._print(term)` before deciding factor-level brackets. | `Subs` must produce an internally unambiguous factor string. | Used as implementation evidence for PO-003, not as intent by itself. |
| E6 | implementation | `parenthesize` wraps exactly when `precedence_traditional(item) < level` under `strict=True`. | This helper matches the needed low-precedence grouping rule. | Used to justify V1 as the implementation of PO-001 and PO-002. |
