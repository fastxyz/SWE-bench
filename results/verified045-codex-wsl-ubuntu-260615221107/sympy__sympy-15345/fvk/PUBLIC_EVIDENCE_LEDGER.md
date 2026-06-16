# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "`mathematica_code(Max(x,2))` ... expect ... `'Max[x,2]'`" | A SymPy `Max` expression in the printer domain must render as a Mathematica call with square brackets. | Encoded by MC-MAX. |
| E2 | prompt | "`'Max(2, x)'` ... is not valid Mathematica code" | Parenthesis-call fallback is forbidden for in-domain `Max`. | Encoded by MC-MAX and finding F1. |
| E3 | prompt hint | "neither Mathematica `Max` or `Min` functions are in" | Treat `Min` as the same printer-family obligation as `Max`. | Encoded by MC-MIN. |
| E4 | prompt hint | "`max` (lowercase `m`) is the Python builtin" | Do not attempt to repair lowercase Python `max`; it is outside this printer contract. | Domain note in SPEC.md. |
| E5 | public test | `test_Function` expects `f[x, y, z]`, `Sin[x]^Cos[x]`, and `Conjugate[x]`. | Ordinary Mathematica function printing uses square brackets and should be preserved. | Encoded by MC-FUNCTION-FRAME. |
| E6 | source code | `MCodePrinter._print_Function` formats `"%s[%s]"`. | Delegating `Max`/`Min` to this method yields the intended bracket shape and preserves known/user function handling. | Used in proof obligations PO1-PO3. |
| E7 | source code | `CodePrinter._print_Expr = _print_Function`; unsupported expressions call `_print_not_supported`, then `emptyPrinter`. | Without class-specific methods, `Max`/`Min` reach inherited fallback and print as repr-style parentheses. | Root cause; resolved by V1. |
| E8 | source code | `MinMaxBase.__new__` stores a canonical frozenset-derived argument set. | The printer cannot promise original source argument order; it prints `expr.args`. | Encoded as scope/assumption. |
