# FINDINGS

Constructed, not machine-checked.

## F1: Resolved Code Bug - Max Used Unsupported Fallback Before V1

Input: `mathematica_code(Max(x, 2))`

Observed before V1, per the public issue: `Max(2, x)`.

Expected: Mathematica function-call syntax, represented by the spec as
`Max[2, x]` for the canonical `expr.args` order.

Cause: `Max` is not dispatched through `MCodePrinter._print_Function` unless
`MCodePrinter` defines a class-specific `_print_Max`. Without that method,
printer dispatch reaches the inherited `CodePrinter._print_Expr` path and then
the unsupported fallback.

V1 status: resolved. `_print_Max` delegates to `_print_Function`, so the
constructed proof obligation MC-MAX reaches bracket-call output.

Trace: E1, E2, E6, E7; PO1.

## F2: Resolved Family Gap - Min Has The Same Printer Obligation

Input family member: `mathematica_code(Min(x, 2))`

Observed risk before V1: the same inherited fallback mechanism as `Max`.

Expected: Mathematica function-call syntax, represented as `Min[2, x]` for the
canonical `expr.args` order.

V1 status: resolved. `_print_Min` delegates to `_print_Function`, discharging
MC-MIN.

Trace: E3, E6, E7; PO2.

## F3: No Source-Order Obligation Found

Input: source text `Max(x, 2)`.

Potential expectation: output exactly `Max[x,2]` in source argument order.

Audit result: no code change justified. The public issue's observed output is
already `Max(2, x)`, showing that SymPy canonicalization has occurred before
printing. `MinMaxBase` also stores canonicalized arguments. The printer can
only specify and print `expr.args`.

Trace: E1, E8; PO5.

## F4: Known-Functions-Table-Only Fix Rejected

Potential change: add `Max` and `Min` only to `known_functions`.

Audit result: insufficient. Because `Max`/`Min` dispatch reaches the inherited
`CodePrinter._print_Expr` method before `MCodePrinter._print_Function`, a table
entry alone does not reliably establish the bracket-call path being specified.
Class-specific printer methods are the targeted repair.

Trace: E6, E7; PO1, PO2.

## F5: No Compatibility Finding

Input surface: `MCodePrinter` and `mathematica_code` public output API.

Audit result: no compatibility problem found. V1 adds two standard printer
methods with the existing `(self, expr)` signature and does not change callers,
ordinary function printing, or generic unsupported fallback behavior.

Trace: PUBLIC_COMPATIBILITY_AUDIT.md; PO3, PO4, PO6.

## Proof-Derived Findings From Verify

No additional source defect was found while constructing the proof obligations.
The proof remains constructed, not machine-checked, because this task forbids
running K tooling.
