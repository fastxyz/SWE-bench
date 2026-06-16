# Baseline Notes

## Root cause

`Function._eval_evalf` used the `_imp_` fallback only as a direct conversion to
`Float`. When an implemented function returned a SymPy expression containing
another implemented function, such as `f(g(2))`, that returned expression was
not sent back through evalf. The direct `Float(...)` conversion failed on the
unevaluated inner `g(2)` expression, so the outer evalf path gave up and left
the whole expression unchanged.

## Changed files

`repo/sympy/core/function.py`

The `_imp_` fallback now sympifies the implementation result and, when that
result is numeric, evaluates it recursively through `_evalf(prec)`. This allows
nested implemented functions to evaluate while preserving the internal binary
precision argument used by `_eval_evalf`.

`reports/baseline_notes.md`

Added this report to document the root cause, the source edit, and the
assumptions behind the fix.

## Assumptions and alternatives

I assumed `_imp_` should continue to behave as a numerical implementation for
evalf, not as a symbolic rewrite rule. For that reason, the change only recurses
when the sympified implementation result is numeric. This preserves the
existing behavior where `f(x).evalf()` remains `f(x)` instead of rewriting to
the implementation body with free symbols.

I considered replacing the old `Float(...)` call with public
`result.evalf(...)`. I rejected that in favor of `result._evalf(prec)` because
`_eval_evalf` receives binary precision, and the surrounding core code uses
`_evalf(prec)` for recursive evaluation at that layer.

I also considered evaluating the arguments before calling `_imp_`, but that
would be a broader behavioral change. The issue only requires recursive evalf
on the implementation result, so the fix leaves argument handling unchanged.
