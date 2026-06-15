# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Formal Core

Semantics: `fvk/mini-numberformat.k`.

Claims: `fvk/numberformat-spec.k`.

The model abstracts the relevant Decimal cutoff decision:

`formatDecimal(Sign, IsZero, Exponent, DigitLength, DecimalPos, Cutoff)`.

`FixedZero(Sign, N)` represents the downstream existing string construction
from `str_number == "0"` or `"-0"` with `decimal_pos == N`.

`Scientific` represents the pre-existing exponent fallback.

## Constructed Proof Sketch

Claim C1: the reported case.

`formatDecimal(pos, false, -200, 1, 2, true)` satisfies the nonzero tiny rule
because `2 >= 0`, `-200 < 0`, and `-200 + 1 <= -2`. By the second semantics
rule, it rewrites in one step to `FixedZero(pos, 2)`. This discharges PO1.

Claim C2: zero-valued Decimals.

For arbitrary `SIGN`, `EXP`, `LEN`, `N`, and `CUTOFF`, with `N >= 0`, the first
semantics rule applies when `IsZero == true`. The result is
`FixedZero(SIGN, N)` independent of exponent and cutoff. This discharges PO3
and fixes the V1 gap.

Claim C3: nonzero tiny family.

For arbitrary nonzero Decimal tuple metadata, the precondition
`N >= 0 and EXP < 0 and EXP + LEN <= -N` means the first significant digit lies
beyond the requested decimal width. The second semantics rule rewrites directly
to `FixedZero(SIGN, N)`. This discharges PO2.

Claim C4: non-small cutoff frame condition.

For nonzero cutoff values where the tiny precondition is false, the third
semantics rule rewrites to `Scientific`. This preserves the original memory
protection for large values that the public issue does not require to become
fixed zero. This discharges PO4.

No loop circularity is needed for the changed branch: the code path is a
straight-line conditional before the existing decimal splitting and grouping
logic. The downstream grouping loop is unchanged and its effect on integer part
`"0"` is observationally unchanged for the audited property.

## Adequacy Gate

The English meaning of the claims is:

- C1: the concrete reported cutoff case returns fixed zero shape.
- C2: zero values return fixed zero shape for any non-negative width.
- C3: nonzero values smaller than the displayed fixed width return fixed zero
  shape.
- C4: non-small cutoff values keep the scientific fallback.

These match the intent spec in `fvk/SPEC.md`. The only suspect public-test
evidence is listed as Finding F2 and is not used to weaken the claims.

## Proof-Derived Findings

F3 was discovered during the proof obligation pass: adjusted-exponent arithmetic
is a nonzero-number criterion and cannot by itself cover zero-valued Decimals.

F4 was discovered during compatibility audit: moving the shortcut outside the
cutoff branch would unnecessarily bypass existing fixed formatting, including
subclass formatting. V2 confines the shortcut to the cutoff branch and attempts
same-class zero formatting for subclasses.

## Machine-Check Commands

These commands were not run:

```sh
kompile fvk/mini-numberformat.k --backend haskell
kast --backend haskell fvk/numberformat-spec.k
kprove fvk/numberformat-spec.k
```

Expected result in a compatible K environment: `kprove` returns `#Top` for all
claims.

## Test Guidance

Do not remove tests unless the K proof is machine-checked and the Django test
suite is run in a real environment.

Tests that would be subsumed after machine-checking:

- Concrete in-domain examples of `Decimal('1e-200')` with `decimal_pos=2`.
- Concrete zero-valued cutoff examples such as `Decimal('0E-200')` with a
  non-negative `decimal_pos`.
- Concrete nonzero tiny values whose adjusted exponent is below `-decimal_pos`.

Tests to keep:

- Non-Decimal formatting tests.
- Localization and grouping integration tests.
- Decimal subclass formatting tests.
- Large non-small cutoff tests that must remain scientific.
- Any test that exercises behavior outside the mini semantics in
  `fvk/mini-numberformat.k`.
