# Findings

Status: V1 stands unchanged.

## F1: Legacy path drops main-variable content

- Evidence: `dmp-ext-factor-spec.k` legacy diagnostic claim.
- Concrete case: abstract `poly(1, 1, {YMINUS1}, {XMINUS1})`.
- Observed legacy result: `factored(1, {XMINUS1})`.
- Expected result: `factored(1, {YMINUS1, XMINUS1})`.
- Classification: code bug in pre-V1 candidate generation.
- Resolution: V1 addresses this by factoring `cont` before `dmp_sqf_part` and
  appending lifted content factors before trial division.

## F2: General proof has algebraic helper boundaries

- Evidence: `dmp-ext-factor-obligations.k`.
- Open obligations: `BAG-COVERAGE`, `TRIAL-MULTIPLICITY`,
  `PRIMITIVE-SPLIT`, and `NORM-CANDIDATES`.
- Classification: proof capability gap, not a V1 counterexample.
- Reasoning: these obligations are existing algebraic and structural facts
  about SymPy's dense polynomial helpers. V1 relies on the same norm-candidate
  obligation as the original code for primitive factors and adds a content path
  through existing helpers.
- Required source edit: none.

## F3: Regression audit did not find a forced edit

- No-content scenario: V1's content candidate list is empty, so the primitive
  path is preserved.
- Content-only scenario: V1 returns through existing `dmp_trial_division`, now
  with the lower-variable content candidates present.
- Repeated-factor scenario: multiplicity remains owned by
  `dmp_trial_division`, so V1 does not need to duplicate candidates.
- Coefficient scenario: V1 multiplies the content factorization coefficient
  into `lc`.
- Classification: confirmation finding.
- Required source edit: none.

## Test recommendations

No tests were edited. Existing and hidden tests should be kept until the emitted
K commands are actually machine-checked and return `#Top`.
