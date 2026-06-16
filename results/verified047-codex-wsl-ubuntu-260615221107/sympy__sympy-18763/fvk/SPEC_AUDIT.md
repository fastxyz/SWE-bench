# Spec Audit

| Formal claim | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| Issue additive product renders as `3 \left. \left(- x + y\right) ...` | Intent 1, 2, 3; ledger E1-E3 | Pass | The formal string matches the issue's desired form, including grouping inside the bar rather than around all of `Subs`. |
| `PREC < 50` bodies are wrapped inside `_print_Subs` | Intent 2; ledger E3, E6 | Pass | This generalizes the additive example using the printer's existing precedence convention. |
| `PREC >= 50` bodies are not wrapped | Intent 4; ledger E4, E6 | Pass | This preserves the public `Subs(x*y, ...)` behavior because multiplication precedence equals the threshold and `strict=True` does not wrap equality. |
| Multiplication composes by prefixing the already-rendered `Subs` factor | Intent 1, 3; ledger E5 | Pass | The proof models the observable interaction that produced the bug without changing multiplication itself. |
| Public API/signature unchanged | Intent 5 | Pass | V1 changes only the expression used for `latex_expr`; no signature, import, or caller contract changes. |
