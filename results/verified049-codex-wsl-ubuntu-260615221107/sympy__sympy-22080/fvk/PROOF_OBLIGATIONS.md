# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Negative modulo containment

For all expressions `a` and `b` printed by `PythonCodePrinter`, `-Mod(a, b)` must generate Python code parsed as `-(a % b)`.

Source: F-001, intent I-001.

Formal claim: K-CLAIM-MOD-NEG in `pycode-mod-precedence-spec.k`.

Discharge argument: `CodePrinter._print_Mul` uses context level `PRECEDENCE["Add"]` after extracting a negative coefficient. `_precedence(Mod(...))` returns `PRECEDENCE["Add"]`, and non-strict `parenthesize` wraps on equality.

## PO-002: External multiplier preservation

For all external factors `c`, `c*Mod(a, b)` must generate Python code parsed as `c*(a % b)` or an equivalent multiplication whose factor is the whole modulo expression.

Source: F-001, intent I-002.

Formal claim: K-CLAIM-MOD-MUL.

Discharge argument: positive multiplication uses context level `PRECEDENCE["Mul"]`; modulo containment precedence is `PRECEDENCE["Add"]`, so `parenthesize` wraps the `%` expression.

## PO-003: Modulo operand grouping

For operands of `Mod(a, b)`, the `%` printer must preserve grouping for low- or equal-precedence operands, including multiplicative right operands.

Source: F-004, intent I-003.

Formal claim: K-CLAIM-MOD-OPERANDS.

Discharge argument: `_print_Mod` continues to compute `PREC = precedence(expr)`, which is generic function precedence for exact `Mod`. It passes that high level to operand `parenthesize`, so additive and multiplicative operands are wrapped as needed.

## PO-004: Python-printer scope

The fix must not modify the global `StrPrinter` precedence table or non-Python printers.

Source: E-005, intent I-004.

Formal claim: file-scope/frame obligation in `SPEC.md`.

Discharge argument: only `repo/sympy/printing/pycode.py` is modified. `repo/sympy/printing/precedence.py`, `str.py`, `latex.py`, `numpy.py`, and `lambdify.py` are unchanged by this FVK pass.

## PO-005: Inherited `_print_Mod` compatibility

If printer dispatch reaches `_print_Mod` through a `Mod` superclass, containment precedence must match exact `Mod`; if an object defines the printer's custom printmethod, generic/custom precedence is preserved.

Source: F-002, intent I-005.

Formal claim: K-CLAIM-MOD-SUBCLASS.

Discharge argument: `_precedence` checks `not hasattr(item, self.printmethod)` before looking for `Mod` in `item.__class__.__mro__`.

## PO-006: Lambdify path preservation

`lambdify(..., modules=[])` must continue to choose the existing Python printer path, but that path must now emit grouped modulo code.

Source: F-003, intent I-004.

Formal claim: compatibility obligation in `SPEC.md`.

Discharge argument: no code in `repo/sympy/utilities/lambdify.py` is changed. The selected printer gets the fixed `parenthesize` behavior through `PythonCodePrinter`.
