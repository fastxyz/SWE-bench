# PROOF_OBLIGATIONS

Constructed, not machine-checked.

| ID | Obligation | Evidence | Status |
|---|---|---|---|
| PO1 | `Max` dispatch must select `MCodePrinter._print_Max` before inherited `_print_Expr`, and `_print_Max` must return `_print_Function(expr)`. | Source: V1 methods in `mathematica.py`; dispatch order in `Printer._print`. | DISCHARGED by source inspection and MC-MAX. |
| PO2 | `Min` dispatch must select `MCodePrinter._print_Min` before inherited `_print_Expr`, and `_print_Min` must return `_print_Function(expr)`. | Source: V1 methods in `mathematica.py`; dispatch order in `Printer._print`. | DISCHARGED by source inspection and MC-MIN. |
| PO3 | `_print_Function` must produce bracket-call syntax for unmapped names such as `Max` and `Min`. | Source: fallback expression `expr.func.__name__ + "[%s]"`. | DISCHARGED for output shape. |
| PO4 | V1 must preserve ordinary function bracket printing. | Public tests for `f`, `sin`, `conjugate`; V1 does not alter `_print_Function`. | DISCHARGED by MC-FUNCTION-FRAME. |
| PO5 | The spec must not assert original source argument order. | Public issue observed canonical `Max(2, x)`; `MinMaxBase` canonicalizes args. | DISCHARGED as scope condition over `expr.args`. |
| PO6 | V1 must preserve unsupported generic `Expr` fallback behavior outside `Max`/`Min`. | V1 adds only `_print_Max` and `_print_Min`; no `_print_Expr` override. | DISCHARGED by MC-EXPR-FALLBACK-FRAME. |
| PO7 | Public compatibility must hold: no changed public function signature, return type, or virtual dispatch protocol. | Compatibility audit. | DISCHARGED. |
| PO8 | Machine-checking commands must be emitted but not run in this environment. | User forbids running K tooling. | SATISFIED by PROOF.md commands and honesty labels. |

## Verification Commands To Run Later

Do not run these in this benchmark session. They are emitted for a future
environment with K installed:

```sh
cd fvk
kompile mini-python-printer.k --backend haskell
kast --backend haskell mathematica-printer-spec.k
kprove mathematica-printer-spec.k
```

Expected machine-check result after a successful run: `#Top`.
