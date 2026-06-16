# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Concrete dilogarithm value at `1/2`

Intent source: E-001 and E-002.

Code path: `polylog.eval` in `repo/sympy/functions/special/zeta_functions.py`.

Precondition: arguments are SymPy expressions with `s == 2` and `z == S.Half`.

Postcondition: construction of `polylog(2, S.Half)` returns `pi**2/12 - log(2)**2/2`.

Proof sketch: the `z == 1`, `z == -1`, and `z == 0` branches do not match `S.Half`; the next branch matches `s == 2 and z == S.Half` and returns the required expression. Since construction already returns the closed form, `expand(func=True)` cannot leave an unevaluated `polylog(2, 1/2)`.

Status: discharged by source inspection and claim C-001.

Findings: F-001, F-004.

## PO-002: Order-one expansion has no `exp_polar`

Intent source: E-003 and E-004.

Code path: `polylog._eval_expand_func`.

Precondition: `s == 1`; `z` is any expression in the symbolic domain of the identity.

Postcondition: function expansion returns `-log(1 - z)`.

Proof sketch: the first branch in `_eval_expand_func` matches `s == 1` and returns `-log(1 - z)`. The old expression containing `exp_polar(-I*pi)` is no longer imported or constructed in this method.

Status: discharged by source inspection and claim C-002.

Findings: F-002, F-004.

## PO-003: `lerchphi` expansion safely handles evaluated `polylog` subterms

Intent source: E-007 and proof-derived finding F-003.

Code path: rational-`a` branch of `lerchphi._eval_expand_func`.

Precondition: rational `a` branch constructs a subterm `polylog(s, zet**k*root)`.

Postcondition: the subterm is passed to `expand_func(..., deep=False)` rather than having `_eval_expand_func` invoked directly on its result.

Proof sketch: the list comprehension now constructs `expand_func(polylog(s, zet**k*root), deep=False)`. If `polylog(...)` remains unevaluated, the public helper performs the function expansion. If `polylog(...)` evaluates to a plain expression such as the `Add` from PO-001, the helper returns a valid expanded expression instead of requiring a private method on that expression.

Status: discharged by V2 source change and claim C-003.

Findings: F-003.

## PO-004: Frame conditions for existing polylog behavior

Intent source: E-005.

Code path: `polylog.eval` and `polylog._eval_expand_func`.

Preconditions and postconditions:

- `z == 1` still returns `zeta(s)`.
- `z == -1` still returns `-dirichlet_eta(s)`.
- `z == 0` still returns `0`.
- `s.is_Integer and s <= 0` still expands through the existing derivative-generated rational function path.
- Other unhandled `polylog(s, z)` values still return `polylog(s, z)` from `_eval_expand_func`.

Proof sketch: V2 adds one `elif` after the existing `z` special cases and changes only the `s == 1` expansion expression. The nonpositive integer branch and fallback are otherwise unchanged.

Status: discharged by source inspection.

Findings: F-005.

## PO-005: No forbidden execution or test edits

Intent source: benchmark instructions and FVK honesty gate.

Obligations:

- Do not run tests, Python code, or K tooling.
- Do not modify test files.
- Record commands needed for later machine checking.
- Label proof results as constructed, not machine-checked.

Status: discharged. Only file-reading shell commands and source/report edits were used.

Findings: F-004, F-006.
