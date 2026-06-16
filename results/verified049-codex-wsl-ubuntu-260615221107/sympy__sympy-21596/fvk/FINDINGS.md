# FVK Findings

Status: constructed, not machine-checked.

## F1 - Zero-imaginary roots were treated as exclusions

- Classification: code bug in the pre-V1 implementation.
- Evidence: E1-E4, PO1-PO2.
- Input: `imageset(Lambda(n, n + (n - 1)*(n + 1)*I), S.Integers).intersect(S.Reals)`.
- Observed pre-V1 behavior: the handler subtracted roots of the imaginary part
  from the base set and wrapped multiple roots as one tuple element.
- Expected behavior: keep exactly `n = -1` and `n = 1`, yielding
  `FiniteSet(-1, 1)`.
- V1 status: RESOLVED. V1 intersects the base set with `FiniteSet(*roots)`.

## F2 - Existing public test expectation is SUSPECT

- Classification: stale or legacy public test evidence, not a code obligation.
- Evidence: E6, SPEC_AUDIT row "Legacy complement".
- Input: same reported `ImageSet`.
- Observed public test expectation: `Complement(S.Integers, FiniteSet((-1, 1)))`.
- Expected per prompt: `FiniteSet(-1, 1)`.
- V1/V2 status: REJECTED AS SPEC SOURCE. The test file was not modified because
  the task forbids test edits.

## F3 - Denominator exclusion must remain an exclusion

- Classification: compatibility/frame condition.
- Evidence: E5, PO3.
- Input: `imageset(Lambda(n, 1/n), S.Integers).is_subset(S.Reals)`.
- Risk: A repair that simply declared the image real whenever `im(n) == 0`
  could make the subset query true despite `n = 0` being undefined.
- Expected behavior: denominator-zero values are removed from the real
  intersection, so the subset fallback does not prove equality to the original
  image set.
- V1 status: CONFIRMED. V1 keeps denominator roots as exclusions and fixes the
  denominator-factor source from `im` to the denominator expression itself.

## F4 - Factor-structure dependency is acceptable for the reported path

- Classification: proof-side implementation check.
- Evidence: E7, PO2.
- Concern: If the imaginary part were expanded to `n**2 - 1`, the linear-factor
  helper might fall back to a `ConditionSet` rather than the finite output.
- Static audit result: `expand_complex` is called with `mul=False` and
  `multinomial=False`, and `Mul.as_real_imag` preserves the reported product's
  factors. Therefore the reported expression reaches the helper as
  `(n - 1)*(n + 1)`.
- V1 status: CONFIRMED for the issue path. No code edit required.

## F5 - Formal proof not machine-checked

- Classification: proof process limitation, not a source bug.
- Evidence: FVK docs and no-exec task instruction.
- Status: The K artifacts and proof are constructed only. The emitted
  `kompile` and `kprove` commands must be run later before claiming
  machine-checked verification or removing tests.

