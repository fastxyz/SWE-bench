# FVK Notes

The FVK audit confirms V1 without further source edits.

## Decisions

1. Kept `Permutation._af_new` as a classmethod using
   `Basic.__new__(cls, perm)`.

   Trace: `fvk/FINDINGS.md` F1; `fvk/PROOF_OBLIGATIONS.md` PO1.

2. Kept `Permutation.__new__` fast paths routed through `cls._af_new(...)`.

   Trace: `fvk/FINDINGS.md` F2; `fvk/PROOF_OBLIGATIONS.md` PO2.

3. Kept the existing-permutation conversion logic from V1: return an existing
   object only when it is already an instance of the requested class; otherwise
   allocate the requested class.

   Trace: `fvk/FINDINGS.md` F2; `fvk/PROOF_OBLIGATIONS.md` PO3.

4. Kept subclass-preserving instance and classmethod results from V1.

   Trace: `fvk/FINDINGS.md` F4; `fvk/PROOF_OBLIGATIONS.md` PO4.

5. Did not change external module-level aliases to `_af_new`.

   Trace: `fvk/FINDINGS.md` F3; `fvk/PROOF_OBLIGATIONS.md` PO5.

6. Did not attempt to prove or edit unrelated permutation algebra,
   validation, ranking, or termination behavior.

   Trace: `fvk/FINDINGS.md` F5; `fvk/PROOF_OBLIGATIONS.md` PO6 and PO8.

## Commands

No tests, Python code, or K commands were run. The commands needed for later
machine-checking are written in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.

