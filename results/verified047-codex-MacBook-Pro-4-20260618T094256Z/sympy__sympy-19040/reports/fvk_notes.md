# FVK Notes

## Decision

V1 stands unchanged. I did not edit any source file during the FVK audit.

The controlling finding is `fvk/FINDINGS.md`:

- `F1` confirms the legacy bug mechanism: the pre-V1 path has only primitive
  norm candidates and drops the `YMINUS1` content factor.
- `F2` records the remaining proof boundaries as algebraic/helper obligations,
  not concrete V1 counterexamples.
- `F3` records the regression audit scenarios and found no forced source edit.

## Artifacts written

All FVK artifacts are outside `repo/` under `fvk/`:

- `mini-factor.k`: a small K semantics that abstracts a polynomial to a
  coefficient plus content and primitive factor bags.
- `dmp-ext-factor-spec.k`: K claims for the issue case, legacy diagnostic,
  no-content frame, content-only frame, coefficient handling, and the general
  V1 contract.
- `dmp-ext-factor-obligations.k`: explicit escalation-boundary claims for bag
  coverage, trial-division multiplicity, primitive split soundness, and
  norm-candidate completeness.
- `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `SPEC.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`,
  `PUBLIC_COMPATIBILITY_AUDIT.md`, `FINDINGS.md`, and `PROOF.md`.

## Why no code edit was made

The issue obligation is that `factor((x - 1)*(y - 1), extension=[I])` must not
drop `y - 1`. In `fvk/dmp-ext-factor-spec.k`, the issue claim models this as
`poly(1, 1, {YMINUS1}, {XMINUS1})` and V1 reaches
`factored(1, {YMINUS1, XMINUS1})`. The adjacent legacy diagnostic reaches only
`factored(1, {XMINUS1})`, which localizes the pre-V1 defect to missing content
candidates.

The regression-sensitive scenarios are covered in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` and `fvk/FINDINGS.md`:

- No-content inputs keep the existing primitive/norm path.
- Content-only inputs now return lower-variable factors through the existing
  trial-division return shape.
- Repeated factors still get multiplicity from `dmp_trial_division`.
- Content scalar coefficients are multiplied into `lc`.

No FVK finding established a concrete V1 failure, and the task's revision
discipline requires leaving V1 unchanged unless such a finding exists.

## Verification status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, `kast`, or `kprove`. The exact commands are recorded in
`fvk/PROOF.md` for later reproduction.
