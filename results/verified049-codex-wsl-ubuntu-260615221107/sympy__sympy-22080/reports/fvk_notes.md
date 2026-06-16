# FVK Notes

Status: FVK audit complete; proof constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Decisions

1. Kept the V1 diagnosis that the root cause is Python printer parenthesization for `Mod` rendered as `%`.

Trace: `fvk/FINDINGS.md` F-001 and `fvk/PROOF_OBLIGATIONS.md` PO-001. The public issue gives `pycode(-Mod(x, y)) -> '-x % y'`, so the repair must make the generated parse tree `-(x % y)`.

2. Kept the fix scoped to `repo/sympy/printing/pycode.py`.

Trace: F-003, F-004, PO-003, PO-004, and PO-006. The direct `pycode` reproduction rules out a lambdify-only fix, and `precedence.py` is shared by printers that do not emit `Mod` as `%`.

3. Revised V1's exact-class check for `Mod`.

Trace: F-002 and PO-005. The printer dispatcher searches the class MRO, so a `Mod` subclass without a custom `_pythoncode` can inherit `_print_Mod`. V1's `item.__class__.__name__ == "Mod"` did not cover that case. The source now checks for `Mod` in the MRO, but only when the object does not define the printer's custom printmethod.

4. Left `_print_Mod` operand parenthesization unchanged.

Trace: F-004 and PO-003. `_print_Mod` still uses generic function precedence for its operands, preserving safe output for cases like `Mod(x, y*z)` where the right operand must be grouped.

5. Did not modify tests.

Trace: F-005 and the task constraints. The FVK artifacts include suggested future tests, but this benchmark fixes source only and forbids running or editing tests.

## Files Changed In This FVK Pass

`repo/sympy/printing/pycode.py`

Changed `_precedence` from exact `Mod` class-name matching to MRO-based matching with a custom `_pythoncode` escape hatch. This is the only production-code refinement beyond V1.

`fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, `fvk/ITERATION_GUIDANCE.md`

Added the requested FVK evidence package.

`fvk/mini-python-precedence.k`, `fvk/pycode-mod-precedence-spec.k`

Added the constructed K-core semantics and claims required by the FVK methodology. These were not machine-checked in this environment.
