# FVK Notes

## Decisions

1. I revised V1 rather than confirming it unchanged.

   Finding F2 identified that V1 returned a multi-term imaginary group's
   coefficient-sum `is_zero is False` directly as the Add-level result. Proof
   Obligation PO3 rejected that as a larger proof obligation than the local fix
   needs. The source now uses the coefficient-sum subquery only for `True`
   cancellation, and requires singleton or same-sign local evidence before
   returning `False`.

2. I kept V1's main structural fix of collecting imaginary terms as real
   coefficients.

   Finding F1 and Proof Obligations PO1, PO2, and PO4 justify this. The legacy
   boolean `im` flag was the root cause because it made every zero-real-part
   Add with any definitely imaginary term look nonzero, even when multiple
   imaginary terms could cancel.

3. I preserved the `zero + I` nonzero result.

   Finding F3 and Proof Obligation PO6 trace this to public source evidence:
   existing tests assert `(a + I).is_zero is False`, and the assumptions docs
   say zero is not considered imaginary. The V2 `len(im) == 1` branch keeps
   this behavior.

4. I preserved the `zero + r*I` unknown result.

   Finding F4 and Proof Obligation PO7 require this compatibility. Terms that
   are only known to be imaginary-or-zero still set `im_or_z`, so when the real
   part is zero the handler returns `None`.

5. I made no broader assumptions-framework changes.

   Finding F5 and Proof Obligation PO8 mark lower-level assumption soundness as
   this proof's trusted base. The issue and proof obligations justify a local
   `Add._eval_is_zero` repair, not a rewrite of the assumptions lattice.

## Artifacts

The FVK artifacts are under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-add-is-zero.k`
- `add-is-zero-spec.k`

The K commands are recorded in the artifacts but were not run, as required by
the benchmark instructions.
