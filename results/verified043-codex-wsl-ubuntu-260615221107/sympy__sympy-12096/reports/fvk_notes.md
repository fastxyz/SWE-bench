# FVK Notes

## Decisions

The FVK audit confirmed the core V1 direction: `_imp_` results that sympify to numeric expressions must be recursively evaluated. This is Finding F-001 and proof obligations PO-001 and PO-002. The V2 source keeps that behavior with `result._evalf(prec)`.

The audit also found a V1 compatibility gap. Finding F-002 and PO-005 show that V1 could skip the legacy direct `Float(...)` path for raw values that are Float-compatible but not sympified as numeric SymPy expressions. V2 fixes this by falling back to `Float(imp_result, mlib.libmpf.prec_to_dps(prec))`.

The `is_number` guard remains intentional. Finding F-003 and PO-004 trace it to the public in-repo behavior that `f(x).evalf()` should remain `f(x)` for free-symbol input, so `_imp_` does not become a symbolic rewrite rule.

The precision handling was adjusted in the fallback path because PO-003 requires the internal binary precision to stay binary for `_evalf(prec)`, while public `Float(...)` expects decimal digits. V2 therefore uses `_evalf(prec)` for recursive SymPy evaluation and `prec_to_dps(prec)` only for `Float`.

The recursive branch now also checks that the evaluated result has no `AppliedUndef`. Finding F-005 and PO-009 justify this guard: recursive evalf should not return a numeric-looking expression as a success if an undefined function remains unresolved.

No test files were changed. Finding F-004 and PO-008 require the proof to remain labeled constructed, not machine-checked, so test removal is not justified.

## Changed Files

`repo/sympy/core/function.py`

Revised the `_imp_` fallback in `Function._eval_evalf` to:

1. call `_imp_(*self.args)` once;
2. sympify its result;
3. recursively evaluate numeric SymPy results with `_evalf(prec)`;
4. return recursive results only when no applied undefined function remains;
5. preserve legacy `Float` conversion for remaining direct numeric values with decimal precision converted from `prec`;
6. keep the existing caught-error-to-`None` behavior.

This source change is justified by F-001, F-002, F-005, PO-001, PO-003, PO-005, and PO-009.

`fvk/SPEC.md`

Records the intent spec, public evidence ledger, formal English, spec audit, compatibility audit, and links to the constructed K artifacts.

`fvk/FINDINGS.md`

Records the resolved root cause, the V1 compatibility gap that caused the V2 revision, the symbolic rewrite guard confirmation, and the proof/model boundary.

`fvk/PROOF_OBLIGATIONS.md`

Lists the obligations used to audit V1 and justify V2, especially PO-001 through PO-005 for recursive evaluation, precision, symbolic preservation, and compatibility.

`fvk/PROOF.md`

Gives the constructed proof and the exact K commands to run later. The commands were not executed.

`fvk/ITERATION_GUIDANCE.md`

Summarizes the V2 patch shape, tests to add or confirm in a normal execution environment, and residual risk.

`fvk/mini-sympy-evalf.k` and `fvk/function-evalf-spec.k`

Provide the constructed mini K semantics and claims required by the FVK method. They model only the `_imp_` fallback result classes needed to distinguish the issue, V1, and V2 behaviors.
