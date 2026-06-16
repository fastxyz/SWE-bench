# Public Evidence Ledger

## E1

- Source: `benchmark/PROBLEM.md`
- Quote: "Comparison methods should ideally return `NotImplemented` when unable to make sense of the arguments. This way, the comparison is delegated to the reflected method on the other object..."
- Obligation: unsupported rich comparisons return `NotImplemented` so Python reflected dispatch can run.
- Status: encoded by PO1, PO3, PO5, PO6, PO7.

## E2

- Source: `benchmark/PROBLEM.md`
- Quote: "`f == s` is True ... while `s == f` is False ... If `sympy.Basic.__eq__` instead returned `NotImplemented`, the statement `s == f` would delegate to `Foo.__eq__`..."
- Obligation: `Basic.__eq__` must not return `False` on unknown operands.
- Status: encoded by PO1 and PO4.

## E3

- Source: public hints in `benchmark/PROBLEM.md`
- Quote: "Subclassing won't help in this case, it will just move the problem to line 319 (returns `False` if sympy types are different). Which is to say, `NotImplemented` should be returned in this case too..."
- Obligation: sympified but different SymPy types are unsupported for `Basic.__eq__` and must return `NotImplemented`.
- Status: encoded by PO2.

## E4

- Source: `benchmark/PROBLEM.md`
- Quote: "The other rich comparison methods, `__lt__`, `__ge__`, and so on, behave similarly."
- Obligation: ordering methods should follow the same unsupported-operand fallback rule.
- Status: encoded by PO5 and PO6.

## E5

- Source: `benchmark/PROBLEM.md`
- Quote: "If both sides return `NotImplemented`, the final return value is `False`, as expected."
- Obligation: equality fallback must preserve Python's two-sided dispatch semantics.
- Status: encoded by PO4.

## E6

- Source: `benchmark/PROBLEM.md`
- Quote: "The reason a sympy `Float` and a python `float` compare symmetrically is twofold: sympy implements support for this in `Float.__eq__`, and python's internal `float.__eq__` returns `NotImplemented`..."
- Obligation: keep explicit supported numeric interop definite while using `NotImplemented` for unsupported operands.
- Status: encoded by PO6 and PO8.

## E7

- Source: code in `repo/sympy/core/numbers.py`
- Quote: pre-V1 `Infinity.__eq__`, `NegativeInfinity.__eq__`, and `NaN.__eq__` used singleton identity checks only.
- Obligation: V1's extra `_sympify` in those identity equality methods is implementation drift unless public intent justifies it.
- Status: Finding F4; fixed by V2 and encoded by PO7.

## E8

- Source: FVK methodology, `fvk_materials/knowledge/intent-evidence.md`
- Quote: implementation behavior is evidence only; public intent chooses the spec, and implementation-derived conditions need independent public support.
- Obligation: do not accept V1's singleton sympification as intended merely because V1 introduced it.
- Status: Finding F4; fixed by V2.
