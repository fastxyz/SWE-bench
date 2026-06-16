# FVK Findings

Status: constructed, not machine-checked. Findings are source- and intent-derived; no code or tests were executed.

## F-001: Original modulo precedence bug

Input: `pycode(-Mod(x, y))`.

Observed before the repair, from the public issue: `-x % y`, which Python parses as `(-x) % y`.

Expected: code whose parse tree is `-(x % y)`.

Classification: code bug.

Evidence: `benchmark/PROBLEM.md` direct reproduction and hint that precedence between `-` and `%` is wrong.

Disposition: fixed by PO-001. The Python code printer now treats `_print_Mod` output as requiring parentheses in the negative multiplication context.

## F-002: V1 exact-class check missed inherited `_print_Mod` dispatch

Input: a `Mod` subclass without a custom `_pythoncode` method, printed in a negative context such as `-SubMod(x, y)`.

Observed under V1 by source reasoning: printer dispatch would reach `_print_Mod` through the class MRO, but V1's `_precedence` helper only checked `item.__class__.__name__ == "Mod"`. That left the subclass with generic function precedence, allowing the same unparenthesized negative `%` shape as the original bug.

Expected: subclasses that inherit `_print_Mod` must use the same containment precedence as exact `Mod`.

Classification: V1 code bug / compatibility gap.

Evidence: `repo/sympy/printing/printer.py` dispatches by class plus bases; `_print_Mod` lives on `AbstractPythonCodePrinter`.

Disposition: fixed in V2 by PO-005. `_precedence` now checks the MRO for `Mod`, while preserving generic precedence for objects with their own `_pythoncode` method.

## F-003: Changing `lambdify(modules=[])` semantics would not fix the printer contract

Input: `lambdify([x, y], -Mod(x, y), modules=[])`.

Observed in the issue: this path exposes the bad generated source `return (-x % y)`.

Expected: the printer must generate grouped `%` code on this path, not avoid it by changing module selection to use a named `mod` function.

Classification: rejected alternative.

Evidence: the public hint gives the direct lower-level reproduction `pycode(-Mod(x, y))`.

Disposition: no `lambdify.py` edit. Covered by PO-006.

## F-004: Operand grouping remains a required frame condition

Input: `pycode(Mod(x, y*z))`.

Observed risk if `_print_Mod` reused the containment precedence for operands: output could become `x % y*z`, parsed by Python as `(x % y)*z`.

Expected: output equivalent to `x % (y*z)`.

Classification: frame condition / regression guard.

Evidence: Python `%` and `*` share precedence and associate left-to-right.

Disposition: confirmed by PO-003. `_print_Mod` still uses the generic precedence of `Mod` for operands, preserving the pre-existing safer operand parentheses.

## F-005: Proof is constructed, not machine-checked

Input: FVK proof artifacts.

Observed: K commands were written but not executed because the benchmark forbids running K tooling.

Expected: a later environment can run the emitted `kompile`, `kast`, and `kprove` commands and should get `#Top`.

Classification: proof process caveat, not a code bug.

Disposition: all proof and test-redundancy claims remain conditioned on future machine checking.
