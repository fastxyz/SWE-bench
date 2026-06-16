# FVK Notes

## Source Decision

V1 stands unchanged. The FVK audit did not justify another source edit.

This decision traces to:

- `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1: `Max` now dispatches
  to `_print_Max`, which delegates to `_print_Function` and therefore reaches
  bracket-call output.
- `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO2: the same is true for
  the `Min` sibling identified by the public hint.
- `fvk/PROOF_OBLIGATIONS.md` PO3: `_print_Function` is the established
  Mathematica bracket-call formatter, so the new methods should delegate rather
  than duplicate formatting logic.
- `fvk/PROOF_OBLIGATIONS.md` PO4 and PO6: ordinary function printing and generic
  unsupported fallback behavior remain unchanged. A broader `_print_Expr`
  override would have exceeded the proven obligation.
- `fvk/FINDINGS.md` F5 and `fvk/PROOF_OBLIGATIONS.md` PO7: adding standard
  printer methods with `(self, expr)` signatures creates no public compatibility
  issue.

## Rejected Changes

I did not add only `Max` and `Min` entries to `known_functions`. `fvk/FINDINGS.md`
F4 records why that is insufficient: the defective path is class dispatch
reaching inherited `_print_Expr`, so the class-specific methods are the needed
repair.

I did not try to force source argument order such as `Max[x, 2]`.
`fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO5 record that the printer
receives canonical `expr.args`; the issue's observed `Max(2, x)` already shows
that canonicalization happened before printing.

## Verification Status

The proof is constructed, not machine-checked, because this task forbids running
K tooling. `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md` include the exact
commands for a later environment. No tests, Python, or K commands were run.
