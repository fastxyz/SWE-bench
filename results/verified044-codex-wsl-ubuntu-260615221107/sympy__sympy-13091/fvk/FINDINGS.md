# FVK Findings

Status: constructed, not machine-checked.

## F1 - Fixed: `Basic.__eq__` returned `False` for unknown operands

- Evidence: E1, E2.
- Input class: `s == f`, where `s` is a `Basic` instance and `f` is a custom object not sympifiable by SymPy but whose reflected equality supports `Basic`.
- Pre-fix observed: `Basic.__eq__` returned `False`, so Python did not delegate to `f.__eq__(s)`.
- Expected: `Basic.__eq__` returns `NotImplemented`, allowing reflected dispatch.
- V2 status: fixed by `repo/sympy/core/basic.py`.
- Proof obligations: PO1, PO4.

## F2 - Fixed: mismatched SymPy types needed fallback too

- Evidence: E3.
- Input class: `s == f`, where both operands are SymPy-ish but `type(self) != type(other)` after sympification and the specialized reflected side may know the comparison.
- Pre-fix observed: `Basic.__eq__` returned `False`.
- Expected: `Basic.__eq__` returns `NotImplemented`.
- V2 status: fixed by `repo/sympy/core/basic.py`.
- Proof obligations: PO2, PO4.

## F3 - Fixed: `__ne__` would swallow `NotImplemented`

- Evidence: E1 and the Python rich-comparison dispatch rule.
- Input class: `s != f`, with `s.__eq__(f)` unsupported.
- V1 risk if not handled: `not NotImplemented` would produce a boolean instead of fallback.
- Expected: `__ne__` returns `NotImplemented` when `__eq__` does.
- V2 status: fixed in `Basic` and the core numeric classes that directly negated `__eq__`.
- Proof obligations: PO3, PO6.

## F4 - Fixed in V2: V1 widened singleton equality by sympifying identity-only cases

- Evidence: E7, E8.
- Input class: singleton equality such as `oo == other`, `-oo == other`, or `nan == other`, where `other` is not the identical SymPy singleton but may be sympifiable.
- V1 observed by inspection: V1 added `_sympify(other)` inside `Infinity.__eq__`, `NegativeInfinity.__eq__`, and `NaN.__eq__`; if sympification produced the singleton, V1 could return `True` where the previous identity method returned `False`.
- Expected: preserve definite singleton behavior for known SymPy numbers, but return `NotImplemented` for unsupported non-number operands.
- V2 status: fixed by removing `_sympify` from those equality methods and using `isinstance(other, Number)` only for known numeric `False`.
- Proof obligations: PO7, PO8.

## F5 - Fixed: ordering methods on `Expr` raised before reflected dispatch

- Evidence: E4.
- Input class: `s < f`, `s >= f`, and similar, where `s` is an `Expr` and `f` is not sympifiable but may implement the reflected ordering method.
- Pre-fix observed: `Expr` ordering raised `TypeError` on `SympifyError`.
- Expected: return `NotImplemented` for unsupported operands, leaving recognized invalid complex/NaN ordering as `TypeError`.
- V2 status: fixed by `repo/sympy/core/expr.py`.
- Proof obligations: PO5, PO8.

## F6 - Fixed: numeric overrides bypassed shared fallback

- Evidence: E4, E6.
- Input class: `Integer`, `Rational`, `Float`, `Infinity`, `NegativeInfinity`, `NaN`, or `NumberSymbol` compared with a custom unsupported object.
- Pre-fix observed: numeric overrides returned `False` or raised before Python reflected dispatch.
- Expected: unsupported branches return `NotImplemented`; supported numeric comparisons remain definite.
- V2 status: fixed in `repo/sympy/core/numbers.py`.
- Proof obligations: PO6, PO7, PO8.

## F7 - Residual scope note: package-wide comparison cleanup remains out of scope

- Evidence: O1 and the public hint's "bonus" wording.
- Input class: domain-specific or special-purpose comparison overrides outside the audited shared core paths.
- Observed: the repository contains other comparison methods that may return booleans for unsupported operands.
- Expected for this task: fix the issue's shared `Basic` path and the core `Expr`/numeric overrides that would otherwise bypass it.
- V2 status: no code change. This is documented as future cleanup rather than a blocker.
- Proof obligations: PO9.
