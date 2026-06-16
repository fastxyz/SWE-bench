# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Recursive numeric `_imp_` result

Claim: If `_imp_(*self.args)` sympifies to a numeric SymPy expression `R`, and recursive evaluation leaves no applied undefined function, then `Function._eval_evalf(self, prec)` returns `R._evalf(prec)`.

Evidence: SPEC E-001 and E-003.

V2 code path: `imp_result = self._imp_(*self.args)`; `result = sympify(imp_result)`; `getattr(result, 'is_number', False)`; `result = result._evalf(prec)`; `not result.has(AppliedUndef)`; `return result`.

Discharge status: constructed proof in `PROOF.md`, claims `IMP-NUMERIC-RECURSES` and `ISSUE-COMPOSITION`.

## PO-002: Issue composition example

Claim: For `f(x) = x**2`, `g(x) = 2*x`, and input `f(g(2)).evalf()`, the fallback path evaluates to numeric `16` rather than leaving `f(g(2))`.

Evidence: SPEC E-002.

V2 code path: `_imp_f(g(2))` produces numeric expression `g(2)**2`; PO-001 recurses; inner `_imp_g(2)` returns `4`; power evaluation returns `16`.

Discharge status: constructed proof in `PROOF.md`, claim `ISSUE-COMPOSITION`.

## PO-003: Precision propagation

Claim: The recursive numeric-expression path receives the binary precision `prec` unchanged, while the legacy `Float(...)` fallback receives decimal digits through `prec_to_dps(prec)`.

Evidence: SPEC E-003.

V2 code path: `result._evalf(prec)` and `Float(imp_result, mlib.libmpf.prec_to_dps(prec))`.

Discharge status: constructed proof and direct code inspection.

## PO-004: Non-numeric symbolic `_imp_` result does not rewrite

Claim: If `_imp_(*self.args)` sympifies to an expression whose `is_number` is false, the recursive path is not taken. Ordinary symbolic expressions are not returned as rewrites from `_eval_evalf`.

Evidence: SPEC E-004.

V2 code path: `if getattr(result, 'is_number', False): return result._evalf(prec)`; otherwise fall through to `Float(...)`, whose failure is caught and returns `None`.

Discharge status: constructed proof in `PROOF.md`, claim `SYMBOLIC-NONNUMERIC-NO-REWRITE`.

## PO-005: Legacy raw numeric conversion is preserved

Claim: If `_imp_(*self.args)` returns a raw value accepted by `Float`, and the numeric SymPy recursion path does not apply, `_eval_evalf` returns `Float(imp_result, prec_to_dps(prec))`.

Evidence: SPEC E-005 and Finding F-002.

V2 code path: fallback `return Float(imp_result, mlib.libmpf.prec_to_dps(prec))`.

Discharge status: constructed proof in `PROOF.md`, claim `RAW-FLOAT-FALLBACK`.

## PO-006: Failure behavior is preserved

Claim: Missing `_imp_`, `_imp_` raising `AttributeError`, `TypeError`, or `ValueError`, or unsupported conversion after the legacy `Float` fallback is tried leads to `None` from `_eval_evalf`. Failed sympification alone is not a terminal failure in V2.

Evidence: SPEC E-006 and legacy implementation behavior.

V2 code path: outer `except (AttributeError, TypeError, ValueError): return`.

Discharge status: constructed proof in `PROOF.md`, claim `FAILURE-RETURNS-NONE`.

## PO-007: Public compatibility

Claim: The fix does not change `Function._eval_evalf`'s signature, the `_imp_(*self.args)` call protocol, the mpmath branch, or the `None` fallback convention.

Evidence: SPEC C-001 through C-004.

Discharge status: code inspection; no K claim needed beyond branch frame conditions.

## PO-008: Honesty gate

Claim: The FVK artifacts are constructed but not machine-checked; no test deletion or machine-verified claim is justified until the emitted commands run and return `#Top`.

Evidence: FVK verify honesty gate.

Discharge status: recorded in `PROOF.md`, `FINDINGS.md`, and `ITERATION_GUIDANCE.md`.

## PO-009: Unresolved applied undefined functions do not escape

Claim: If recursive `_evalf(prec)` of a numeric `_imp_` result still contains `AppliedUndef`, the recursive branch does not return that result. The method falls through to legacy `Float` conversion/failure behavior.

Evidence: SPEC E-007 and Finding F-005.

V2 code path: `if result is not None and not result.has(AppliedUndef): return result`; otherwise fallback `Float(imp_result, prec_to_dps(prec))` under the existing catch.

Discharge status: constructed proof in `PROOF.md`, claim `UNRESOLVED-NUMERIC-NO-SUCCESS`.
