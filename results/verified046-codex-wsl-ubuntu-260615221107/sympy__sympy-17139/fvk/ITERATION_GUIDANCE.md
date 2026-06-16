# Iteration Guidance

Status: V2 source changes applied.

## Applied Changes

1. Keep V1's non-integer guard before ordered exponent comparisons.
   This is justified by F1 and PO-1.

2. Add a concrete-`Integer` guard inside the `pow=True` branch before calling
   `perfect_power`.
   This is justified by F2 and PO-6.

3. Require `perfect_power(rv.exp)` to return base `2` before allowing a
   `pow=True` rewrite.
   This is justified by F2 and PO-6.

## Next Checks When Execution Is Available

Run the machine-check commands listed in `fvk/PROOF.md`, then run focused SymPy
tests for `sympy/simplify/fu.py` and a regression for `simplify(cos(x)**I)`.

## No Further Code Changes Recommended Now

The remaining obligations are verification and test execution, both forbidden
in this session. The current source patch satisfies all FVK findings and proof
obligations identified from public intent.
