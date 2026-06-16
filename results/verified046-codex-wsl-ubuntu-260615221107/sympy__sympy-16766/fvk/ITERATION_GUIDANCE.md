# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Verdict

V1 stands unchanged. The FVK audit found no open source-code finding after the
V1 additions of:

- `PythonCodePrinter._print_Indexed`
- `PythonCodePrinter._print_Idx`

This conclusion is justified by F-001 through F-004 and PO-001 through PO-005.

## Recommended Next Actions

1. Keep the V1 source change in `repo/sympy/printing/pycode.py`.
2. In a normal development environment, add focused public tests for the
   `pycode`, `human=False`, `Idx`, multidimensional-index, and `lambdarepr`
   cases listed in `PROOF.md`.
3. In an environment with K installed, run the emitted commands:

   ```sh
   kompile fvk/mini-python-printer.k --backend haskell
   kast --backend haskell fvk/pycode-indexed-spec.k
   kprove fvk/pycode-indexed-spec.k
   ```

4. Do not delete tests based on this pass; the proof has not been
   machine-checked.

## No Further Code Edits

No V2 source edit was made because:

- F-001 is resolved by V1's `_print_Indexed`.
- F-002 is resolved by V1's `_print_Idx`.
- F-003 confirms V1's index-order and separator behavior.
- F-004 confirms compatibility and inheritance behavior.
- F-005 is a tooling caveat, not a production-code defect.

## Open Questions

None for the issue as stated. Broader support for standalone `IndexedBase`
printing, TensorFlow-specific indexed printing, or unsupported nested index
expressions is outside the public intent for this issue and should be handled as
separate requirements if needed.
