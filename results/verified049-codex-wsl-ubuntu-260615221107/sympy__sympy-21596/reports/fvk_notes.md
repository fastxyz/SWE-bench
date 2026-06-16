# FVK Notes

## Decision Summary

V1 stands unchanged as the production fix. The FVK audit found that V1 satisfies
the intent-derived obligations for the reported `ImageSet`/`S.Reals`
intersection, and it did not identify a justified V2 source edit.

## Decisions Traced to Findings and Proof Obligations

1. Kept the production change from subtraction to intersection.

   - Finding: `fvk/FINDINGS.md` F1.
   - Obligations: `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2.
   - Reason: The public issue requires `S1.intersect(S.Reals)` to be
     `FiniteSet(-1, 1)` and `2 in ...` to be false. That requires keeping
     zero-imaginary roots, not subtracting them.

2. Kept `FiniteSet(*xis)`.

   - Finding: F1.
   - Obligation: PO2.
   - Reason: Multiple zero roots must be individual finite-set elements. The old
     `FiniteSet(xis)` shape wrapped `(-1, 1)` as one tuple-like element and
     could not represent the issue's `{-1, 1}` output.

3. Kept denominator roots as exclusions.

   - Finding: F3.
   - Obligation: PO3.
   - Reason: Public behavior from issue #19513 requires
     `imageset(Lambda(n, 1/n), S.Integers).is_subset(S.Reals)` to remain
     undecided, not true. Excluding denominator-zero parameters preserves that
     frame condition.

4. Kept the denominator-factor correction from V1.

   - Finding: F3.
   - Obligation: PO3.
   - Reason: Denominator exclusions must solve denominator factors, not reuse
     the imaginary-part factors. This is a localized correctness repair inside
     the same branch.

5. Kept the `ConditionSet(n, Eq(im, 0), base_set)` fallback.

   - Finding: F1 as the general bug class, with no contrary finding.
   - Obligation: PO4.
   - Reason: If zero roots cannot be enumerated, the exact symbolic condition is
     the parameter domain satisfying `im(n) == 0`, not the complement of that
     condition.

6. Rejected the old public test expectation as a spec source.

   - Finding: F2.
   - Obligation: PO2.
   - Reason: The expected `Complement(S.Integers, FiniteSet((-1, 1)))` conflicts
     with the problem statement's explicit correct output. FVK marks that test
     evidence as SUSPECT. The test file was not edited because the task forbids
     test modifications.

7. Did not make a V2 production-code edit for factorization.

   - Finding: F4.
   - Obligation: PO2.
   - Reason: Static inspection shows `expand_complex` is called with
     `mul=False` and `multinomial=False`; the reported product factors remain
     visible to the linear-factor helper. The concern did not justify changing
     source code.

8. Added FVK artifacts, including extra adequacy and K-core files.

   - Finding: F5.
   - Obligations: all PO entries.
   - Reason: The user required five `fvk/` artifacts, and the FVK docs require
     the intent ledger, adequacy audit, compatibility audit, and `.k` formal
     core for a valid run. The artifacts are labeled constructed, not
     machine-checked.

## Files Changed During FVK Pass

- Added FVK artifacts under `fvk/`.
- Added this report at `reports/fvk_notes.md`.
- Did not edit production source under `repo/` during the FVK pass.
- Did not edit tests.

## Verification Caveat

No tests, Python, `kompile`, `kast`, or `kprove` commands were run. The proof is
constructed only, as required by the task's no-execution rule.

