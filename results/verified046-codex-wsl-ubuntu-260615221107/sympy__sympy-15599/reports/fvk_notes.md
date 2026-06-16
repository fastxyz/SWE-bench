# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit confirmed that the production branch added
in `repo/sympy/core/mod.py` has the right intent-derived guards and implements
the needed integer congruence. No additional source edit was justified.

## Decisions traced to findings and proof obligations

1. Kept the integer coefficient reduction from V1.

   Trace: `fvk/FINDINGS.md` F1 and F5; `fvk/PROOF_OBLIGATIONS.md` PO1 and
   PO2. PO1 proves the general arithmetic fact
   `Mod(C*T, Q) == Mod((C % Q)*T, Q)` for integer `C`, nonzero integer `Q`,
   and integer tail `T`. PO2 specializes that fact to the issue's
   `C = 3`, `Q = 2`, giving `Mod(i, 2)`.

2. Did not broaden V1 into product-wide `Mod` distribution.

   Trace: F2 and F3; PO3, PO4, and PO5. PO3 blocks rational coefficients such
   as `1/2`, which addresses the public `Mod(e/2, 2)` warning. PO4 requires
   the remaining tail to be known integer. PO5 requires the divisor to be a
   plain integer rather than a symbolic product such as `2*y`.

3. Did not change float, additive, or symbolic-divisor code paths.

   Trace: F3; PO4 and PO5. The public hints and existing public tests identify
   these as frame conditions. The V1 guard excludes them, so no further source
   edit was needed.

4. Did not claim a full formal proof of all `Mod.eval`.

   Trace: F4; PO7. The mini-K model covers the V1 coefficient-normalization
   branch and its guard frame, not the complete SymPy expression system. The
   proof is therefore useful for this repair decision but remains
   "constructed, not machine-checked" and scoped.

5. Added FVK artifacts but did not run commands.

   Trace: PO7 and `fvk/PROOF.md`. The artifacts include the requested five
   Markdown files plus the compact K core and adequacy files. The exact
   `kompile`, `kast`, and `kprove` commands are recorded in `fvk/PROOF.md`,
   but the benchmark forbids running them.

## Files added by this FVK pass

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-sympy-mod.k`
- `fvk/sympy-mod-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No test files were modified, and no tests or code were executed.
