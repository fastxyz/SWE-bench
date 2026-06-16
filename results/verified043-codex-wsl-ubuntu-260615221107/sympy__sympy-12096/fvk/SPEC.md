# FVK Spec: sympy__sympy-12096

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

Target source: `repo/sympy/core/function.py`, method `Function._eval_evalf`, only the fallback branch used when no matching mpmath function exists.

The mpmath-backed branch is a frame condition: this audit does not change or respecify it. The proof model abstracts the rest of SymPy to the behavior relevant to `_imp_` fallback evaluation.

## Intent Spec

I-001. For an implemented function whose `_imp_` returns a numeric SymPy expression containing another implemented function, `.evalf()` must recursively evaluate the returned expression.

I-002. The recursive evaluation must receive the internal binary precision argument used by `_eval_evalf`; public decimal precision is only for public `.evalf(...)` or `Float(...)` APIs.

I-003. `_imp_` is a numerical implementation hook, not a symbolic rewrite rule. If the `_imp_` result contains free symbolic input and is not numeric, `.evalf()` should leave the original implemented function unevaluated.

I-004. Existing successful behavior for direct numeric `_imp_` returns must be preserved, including values acceptable to the legacy `Float(...)` conversion path.

I-005. Existing fallback failure behavior must be preserved: missing `_imp_`, `_imp_` errors, or unsupported conversion failures should make `_eval_evalf` return `None` so the caller can leave the original expression unchanged.

I-006. Recursive evaluation must not report success when the evaluated `_imp_` result still contains an applied undefined function. That case remains not evaluable by this fallback.

## Public Evidence Ledger

E-001. Source: prompt. Quote: "evalf does not call _imp_ recursively". Obligation: `_imp_` results that are numeric expressions must be recursively evaluated. Status: encoded by PO-001 and PO-002.

E-002. Source: prompt. Quote: "print(f(g(2)).evalf())" currently prints `f(g(2))`. Obligation: the composition of implemented functions at concrete numeric arguments must not remain unevaluated. Status: encoded by PO-002 and Finding F-001.

E-003. Source: prompt hint. Quote: "pass through the precision". Obligation: preserve the binary precision path for recursive evaluation and convert to decimal digits only when calling `Float`. Status: encoded by PO-003.

E-004. Source: public in-repo test. Quote: `assert f(x).evalf() == f(x)`. Obligation: do not turn `_imp_` into a symbolic rewrite for free-symbol expressions. Status: encoded by PO-004.

E-005. Source: implementation and compatibility. Quote: the legacy code was `Float(self._imp_(*self.args), prec)`. Obligation: direct numeric returns accepted by `Float` should remain accepted. Status: encoded by PO-005 and Finding F-002.

E-006. Source: implementation and API shape. Quote: `_eval_evalf(self, prec)`. Obligation: no public signature or caller protocol change. Status: encoded by PO-006.

E-007. Source: implementation and compatibility. Quote: fallback returns `None` when direct conversion cannot produce a value. Obligation: a recursive result that still contains an applied undefined function should fall back rather than being returned as an apparent success. Status: encoded by PO-009.

## Formal Spec English

FS-001. If mpmath has a matching function for `self.func.__name__` or its translation, `Function._eval_evalf` follows the existing mpmath branch unchanged.

FS-002. If there is no mpmath function and `_imp_(*self.args)` produces a sympifiable numeric expression `R`, the method recursively computes `R._evalf(prec)` and returns it when no applied undefined function remains.

FS-003. In the concrete issue shape, `_imp_f(g(2)) = g(2)**2` and recursive evaluation of `g(2)` uses `_imp_g(2) = 4`, so `f(g(2)).evalf()` reaches the numeric result `16` at the requested precision.

FS-004. If `_imp_(*self.args)` produces a sympifiable expression that is not numeric, the method must not return that expression as a rewrite. It may only fall through to legacy `Float` conversion, which fails for ordinary symbolic expressions and returns `None`.

FS-005. If `_imp_(*self.args)` produces a non-SymPy raw value accepted by `Float`, the method returns `Float(raw, prec_to_dps(prec))`.

FS-006. If `_imp_` is absent, raises `AttributeError`, `TypeError`, or `ValueError`, or if both sympification/recursive evaluation and legacy `Float` conversion fail with those errors, the method returns `None`.

FS-007. If recursive `_evalf(prec)` still leaves an applied undefined function in the result, the recursive branch is treated as not successful and the method falls through to legacy conversion/failure behavior.

## Spec Audit

FS-001 passes: V2 only edits the no-mpmath fallback branch.

FS-002 passes: directly entailed by E-001, E-003, and the E-007 guard for unresolved applied undefined functions.

FS-003 passes: directly entailed by the prompt example and the semantics of the provided `_imp_` lambdas.

FS-004 passes: supported by E-004 and by the public meaning of `implemented_function` as a numerical implementation hook.

FS-005 passes: supported by E-005 as a backward-compatibility frame condition. This was the V1 gap corrected in V2.

FS-006 passes: supported by the legacy catch-and-return behavior in the implementation.

FS-007 passes: supported by E-007 and preserves the old behavior for numeric-looking expressions that still cannot be numerically evaluated.

No formal-English obligation is based only on hidden tests, evaluator output, or upstream patch knowledge.

## Public Compatibility Audit

C-001. Changed symbol: `Function._eval_evalf(self, prec)`. Signature unchanged.

C-002. Public callers: the method is used through SymPy's evalf machinery. Return convention unchanged: return a SymPy expression/value when evaluable, or `None` when not evaluable.

C-003. Virtual dispatch risk: no new call into user-overridable methods with new keyword arguments. The existing `_imp_(*self.args)` call shape is unchanged.

C-004. Type/shape compatibility: V2 preserves direct numeric `Float` conversion for raw returns and uses recursive `_evalf(prec)` only for sympified numeric expressions.

## Formal Artifacts

The constructed K artifacts are:

- `fvk/mini-sympy-evalf.k`
- `fvk/function-evalf-spec.k`

The exact commands to machine-check later are recorded in `fvk/PROOF.md`. They were not run.
