# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Code Decision

V1 stands unchanged. The audit found that V1 satisfies the C/Cython autowrap
intent:

- `MatrixSymbol` redundant arguments now receive dimensions.
- Existing expression-derived arguments are preserved.
- Scalar redundant arguments remain scalar.
- C and Cython consumers already use `arg.dimensions` to select pointer/ndarray
  handling.

This decision is justified by Findings F1-F3 and proof obligations PO1-PO7.

## Future Checks

1. Machine-check the FVK claims when a K environment is available:

   ```sh
   cd fvk
   kompile mini-codegen.k --backend haskell
   kast --backend haskell codegen-spec.k
   kprove codegen-spec.k
   ```

2. Run the SymPy tests when an execution environment is available. This task
   explicitly forbids test execution, so no test result is claimed here.

3. Add future public tests, without modifying tests in this task:

   - `autowrap(1.0, args=(MatrixSymbol('x', 2, 1),), backend='cython')`
     accepts an ndarray and returns `1.0`.
   - C codegen for the same routine emits `double *x`.
   - A redundant scalar `Symbol` remains a scalar argument.
   - A shaped unused `IndexedBase` preserves array metadata.

4. If future public intent expands from C/Cython autowrap to all codegen
   languages, separately audit `JuliaCodeGen.routine`, `OctaveCodeGen.routine`,
   and `RustCodeGen.routine`, which have their own specialized routine builders.

## No Test Removal

Do not remove tests based on this FVK pass. The proof is constructed, not
machine-checked, and this task forbids running tests or tooling.

