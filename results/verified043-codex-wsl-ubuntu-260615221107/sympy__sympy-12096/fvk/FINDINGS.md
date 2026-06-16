# FVK Findings

Status: constructed, not machine-checked. Findings are based only on public prompt evidence, source code, public in-repo tests read for intent, and the constructed proof obligations.

## F-001: Original root cause, resolved and retained in V2

Classification: code bug, resolved.

Input: implemented functions `f(x) = x**2`, `g(x) = 2*x`, expression `f(g(2)).evalf()`.

Observed pre-fix behavior: `f(g(2))` remained unevaluated because `Function._eval_evalf` attempted `Float(_imp_result, prec)` directly. The `_imp_f` result is `g(2)**2`, which is not directly float-convertible before `g(2)` is evaluated.

Expected behavior: `_imp_f(g(2))` must be sent through recursive evalf; `g(2)` evaluates through `_imp_g` to `4`, so the outer result evaluates to `16`.

Evidence: SPEC E-001, E-002. Proof obligations: PO-001, PO-002.

V2 disposition: `Function._eval_evalf` sympifies `_imp_` results and returns `result._evalf(prec)` when the result is numeric. This retains V1's core repair.

## F-002: V1 compatibility gap for direct Float-compatible raw returns, resolved in V2

Classification: compatibility risk, resolved.

Input: an implemented function whose `_imp_` returns a raw value accepted by `Float(...)` but not represented by `sympify(...)` as a numeric SymPy expression.

Observed V1 behavior: V1 only used the sympified `result.is_number` path. If sympification produced a nonnumeric container-like SymPy object, V1 could return `None` without trying the legacy direct `Float` conversion.

Expected behavior: prior successful direct numeric returns should remain accepted because the issue only requires adding recursive evalf for symbolic numeric `_imp_` results, not removing legacy conversion support.

Evidence: SPEC E-005. Proof obligations: PO-003, PO-005.

V2 disposition: after the recursive numeric-expression path, V2 falls back to `Float(imp_result, prec_to_dps(prec))`.

## F-003: Symbolic rewrite avoidance, confirmed

Classification: no code bug after V2.

Input: implemented function `f(x) = x + 1`, expression `f(x).evalf()`.

Observed/expected behavior: the public in-repo test expects `f(x).evalf() == f(x)`. `_imp_` should not rewrite `f(x)` to `x + 1` while free symbols remain.

Evidence: SPEC E-004. Proof obligation: PO-004.

V2 disposition: V2 only recurses when the sympified `_imp_` result is numeric. For `x + 1`, `is_number` is false, so the method falls through and returns `None`.

## F-004: Proof/model boundary, open but non-blocking

Classification: proof capability gap.

Input: full SymPy/Python behavior of `Function._eval_evalf`, including all possible user-defined `_imp_` callables and arbitrary Python object returns.

Observed proof limitation: the constructed K model abstracts the fallback into result classes: numeric SymPy expression, nonnumeric symbolic expression, raw Float-compatible value, and failure. It is not a full Python or full SymPy semantics.

Expected handling: keep the proof labeled constructed, not machine-checked; keep relevant tests until a real K/Python/SymPy semantics and the emitted `kprove` commands discharge.

Evidence: FVK methodology honesty gate. Proof obligations: PO-007, PO-008.

V2 disposition: no extra source change. The abstraction is sufficient to distinguish the reported failing behavior from the fixed behavior, but it is not a substitute for executing the full test suite later.

## F-005: Numeric-looking result with unresolved applied undefined function, resolved in V2

Classification: compatibility risk, resolved.

Input: an implemented function whose `_imp_` returns a numeric SymPy expression that still contains an applied undefined function after recursive `_evalf(prec)`.

Observed V1/V2-before-guard behavior: the recursive branch could return the partially unresolved expression as if evaluation succeeded.

Expected behavior: preserve the legacy not-evaluable convention. If recursive evaluation does not eliminate applied undefined functions, fall through to the legacy `Float` conversion and ultimately return `None` if conversion fails.

Evidence: SPEC E-007. Proof obligation: PO-009.

V2 disposition: after recursive `_evalf(prec)`, V2 returns the result only when `not result.has(AppliedUndef)`.

## Proof-derived findings from /verify

PD-001. PO-005 forced a V1 revision: preserving the legacy `Float` conversion path is required by compatibility evidence E-005 and was not guaranteed by V1. This is resolved by V2.

PD-002. PO-004 blocks an overly broad "always return `sympify(_imp_result).evalf(...)`" repair. Such a repair would violate public evidence E-004 by changing `f(x).evalf()`.

PD-003. PO-007 and PO-008 require all proof conclusions to remain conditioned on machine checking. No tests should be removed based on this constructed proof alone.

PD-004. PO-009 required a V2 guard after recursive `_evalf(prec)` so that unresolved applied undefined functions do not escape as successful numeric evaluation.
