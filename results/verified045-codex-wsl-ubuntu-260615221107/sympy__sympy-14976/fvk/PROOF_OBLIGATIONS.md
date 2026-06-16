# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: mpmath Printer Selection

If `lambdify` receives modules containing `mpmath` and no custom printer, it selects `MpmathPrinter`.

Evidence: `repo/sympy/utilities/lambdify.py` checks `_module_present('mpmath', namespaces)` before NumPy, NumExpr, TensorFlow, SymPy, or generic Python printer selection.

Result: discharged by static source inspection.

## PO-2: Non-Integer Rational Wrapping

For every normalized SymPy rational `p/q` with `q > 1`, `MpmathPrinter._print_Rational` emits mpmath `mpf` calls for the numerator magnitude and denominator, with division between those mpmath values.

Formal claims: positive and negative branches in `mpmath-rational-printer-spec.k`.

Result: discharged by V1 code structure.

## PO-3: Sign and Precedence Preservation

For `p < 0`, the leading sign emitted as `-F(abs(p))/F(q)` must preserve the value `p/q`. Existing `Add`, `Mul`, and `Pow` parenthesizing must preserve grouping when the rational appears inside larger expressions.

Evidence: `StrPrinter._print_Add` treats a leading `-` as a subtraction sign; `CodePrinter._print_Mul` parenthesizes rational factors at multiplication precedence; `StrPrinter._print_Pow` parenthesizes rational exponents.

Result: discharged by static source inspection.

## PO-4: Integer Branch Frame

If `q == 1`, the printer returns `str(p)`. This does not reintroduce the reported precision bug because there is no Python division operation.

Evidence: V1 `_print_Rational` first branch.

Result: discharged.

## PO-5: mpmath Namespace Availability

For `lambdify(..., modules='mpmath')`, unqualified `mpf` must exist in the execution namespace when `fully_qualified_modules=False`.

Evidence: `MODULES["mpmath"]` uses `from mpmath import *`; `_module_format('mpmath.mpf')` returns `mpf` under lambdify's printer settings.

Result: discharged by static source inspection.

## PO-6: Non-mpmath Frame Condition

Rational printing for other backends remains unchanged.

Evidence: V1 adds `_print_Rational` only to `MpmathPrinter`; no base class or other subclass method is edited.

Result: discharged.

## PO-7: Full Observable Contributor Coverage

The issue's observable is a generated expression, not a standalone rational. The fix must cover rational constants whether they appear as full expressions, addends, coefficients, or exponents.

Evidence: printer dispatch applies `_print_Rational` whenever those expression printers render the rational object; parenthesizing covers surrounding operator contexts.

Result: discharged for the audited printer contexts.

## PO-8: Machine-Check Caveat

The `.k` claims and proof are constructed but were not run through `kompile` or `kprove`, per task constraints.

Result: open operational caveat, not a source-code defect.
