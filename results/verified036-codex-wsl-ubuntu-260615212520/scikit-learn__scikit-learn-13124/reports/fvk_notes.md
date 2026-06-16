# FVK Notes

Status: constructed, not machine-checked.

## Decisions

1. V1 stands unchanged.
   - Trace: `fvk/FINDINGS.md` F1 says the legacy bug is resolved by V1.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO2 and PO3 are discharged by
     `_split.py` lines 653-657, where one normalized RNG object is passed to all
     per-class `KFold` splitters.
   - Reason: the public hint identifies same-random-state-per-class as the
     regression, and V1 removes that mechanism without altering the rest of the
     splitter.

2. I did not strengthen the code to guarantee different final splits for every
   possible pair of integer seeds.
   - Trace: `fvk/FINDINGS.md` F2.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` rejected obligation R1.
   - Reason: random outputs can collide in principle; the public intent supports
     removing forced identical class shuffles, not proving global seed
     injectivity.

3. I did not refactor the per-class `KFold` construction.
   - Trace: `fvk/FINDINGS.md` F4.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO5.
   - Reason: unchanged code already handles fold sizes, sample coverage,
     under-populated class trimming, and warnings. Replacing it would enlarge
     the patch without a proof-derived need.

4. I kept RNG normalization after target and class-count validation.
   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO5.
   - Reason: this preserves the legacy validation order more closely than
     validating `random_state` at function entry, while still normalizing the RNG
     before any per-class `KFold` splitter is built.

5. I produced supporting FVK files beyond the five requested artifacts.
   - Trace: FVK `AGENTS.md` requires the formal core and adequacy gate.
   - Files: `fvk/mini-python-stratified-kfold.k`,
     `fvk/stratified-kfold-spec.k`, `fvk/INTENT_SPEC.md`,
     `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`,
     `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Execution policy

No tests, Python code, `kompile`, `kast`, or `kprove` were run. The proof is
constructed by static reasoning only, as required by this benchmark session.
