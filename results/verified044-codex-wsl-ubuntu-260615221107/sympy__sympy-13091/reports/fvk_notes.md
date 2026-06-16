# FVK Notes

## Decisions and traceability

1. Kept the `Basic.__eq__` fallback change.

   - Trace: `fvk/FINDINGS.md` F1 and F2; `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2.
   - Reason: the public issue and hint require `NotImplemented` for both unsympifiable operands and sympified operands whose SymPy type still differs. The V1 edit in `repo/sympy/core/basic.py` satisfies those obligations.

2. Kept the `Basic.__ne__` sentinel-preserving change.

   - Trace: F3; PO3.
   - Reason: once `__eq__` can return `NotImplemented`, direct boolean negation would stop reflected `!=` dispatch. The V1 `eq is NotImplemented` guard is required.

3. Kept the `Expr` ordering fallback change.

   - Trace: F5; PO5 and PO8.
   - Reason: the issue names `__lt__`, `__ge__`, and related rich comparisons. Returning `NotImplemented` on `SympifyError` lets reflected ordering methods run, while the existing complex/NaN invalid-comparison checks remain after successful sympification.

4. Kept the core numeric fallback and `__ne__` changes.

   - Trace: F6; PO6 and PO8.
   - Reason: numeric classes override the shared `Basic`/`Expr` methods, so leaving them unchanged would preserve the same non-delegating behavior for common SymPy objects such as `Integer`, `Rational`, and `Float`. Supported numeric comparisons remain definite.

5. Revised V1 singleton equality for `Infinity`, `NegativeInfinity`, and `NaN`.

   - Trace: F4; PO7 and PO8.
   - Reason: V1 added `_sympify(other)` to equality methods that were previously identity/known-number checks. That was implementation-derived drift, not public intent. V2 removes that sympification and now returns `True` only for the identical singleton, `False` for other known `Number` instances, and `NotImplemented` for unsupported non-number operands.

6. Did not expand the patch to every comparison method in the package.

   - Trace: F7; PO9.
   - Reason: the public issue requires the shared `Basic` path and rich-comparison fallback behavior; the broader package-wide cleanup is described as a possible bonus. No signatures or test files were changed.

## Verification status

The FVK proof is constructed, not machine-checked. I did not run tests, Python, `kompile`, `kast`, or `kprove`, per the task constraints. The exact future K commands are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
