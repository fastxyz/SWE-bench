# FVK Specification: django__django-11206

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Target

Function under audit: `django.utils.numberformat.format()` in
`repo/django/utils/numberformat.py`.

The changed behavior is the `Decimal` branch when the 200-digit cutoff would
otherwise route formatting through scientific notation.

## Intent Spec

1. If `decimal_pos` is supplied, the formatter should use exactly that many
   fractional positions.

2. If a `Decimal` is smaller in absolute value than the lowest nonzero value
   displayable with `decimal_pos` fractional places, the output should be the
   fixed zero shape for that width, not exponential notation.

3. Zero-valued `Decimal`s are representable at every non-negative
   `decimal_pos` and therefore must also use the fixed zero shape.

4. The existing scientific-notation cutoff for very large non-small `Decimal`
   values remains a frame condition because the source comment says it avoids
   high memory use in fixed formatting.

5. Existing non-cutoff fixed formatting remains a frame condition; V2 must not
   preempt that path because public tests show it is used for ordinary
   `Decimal` and `Decimal` subclass values.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`utils.numberformat.format` renders small decimals in exponential notation." | The observable defect is exponential notation for small decimals. | Encoded in claims C1 and C3. |
| E2 | prompt | `nformat(Decimal('1e-199'), '.', decimal_pos=2) == '0.00'` while `Decimal('1e-200')` produced `'1.00e-200'`. | The cutoff boundary must not change the intended fixed-zero result. | Encoded in claim C1. |
| E3 | prompt | "when a `decimal_pos` argument is supplied and the number ... is smaller in absolute size than what can be encoded ... the returned string should be `0.0000...000`" | For nonzero decimals, adjusted exponent `< -decimal_pos` implies fixed zero. | Encoded in claim C3. |
| E4 | source comment | "Format values with more than 200 digits ... using scientific notation to avoid high memory usage" | Preserve scientific notation for cutoff values not covered by the small-zero rule. | Encoded in claim C4. |
| E5 | public tests | `nformat(Decimal('9e-19'), '.', decimal_pos=2) == '0.00'` and `nformat(Decimal('.00000000000099'), '.', decimal_pos=0) == '0'` | Existing fixed formatting truncates rather than rounds. | Supports the threshold formula. |
| E6 | public tests | `EuroDecimal('1.23')` preserves subclass `__format__()` output. | Do not preempt the normal fixed-format path where the cutoff is not active. | Addressed by V2 source change; listed in proof obligation PO6. |
| E7 | public tests | `('0.{}1234'.format('0' * 299), 3, '1.234e-300')` | This is SUSPECT legacy evidence because it conflicts with E3 for the same value family. | Recorded as Finding F2, not used as intent. |
| E8 | V1 audit | `Decimal('0E-200')` with `decimal_pos=200` has no significant digit, but V1's nonzero threshold did not classify it as fixed zero. | Zero must be handled independently from adjusted-exponent arithmetic. | Addressed by V2 and claim C2. |

## Domain

The formal claims cover finite `Decimal` inputs represented by:

- sign `SIGN`;
- `is_zero()` result `ISZERO`;
- tuple exponent `EXP`;
- digit length `LEN`;
- non-negative integer `decimal_pos` `N`;
- cutoff boolean `CUTOFF`, abstracting `abs(exponent) + len(digits) > 200`.

The proof focuses on the observable distinction relevant to the issue:
`FixedZero(SIGN, N)` versus `Scientific`. `FixedZero(SIGN, N)` represents the
string produced by the downstream existing logic from `str_number == "0"` or
`"-0"`: optional sign, integer part `0`, and `N` zero fractional digits when
`N > 0`.

The spec does not model localization settings, arbitrary string inputs,
non-Decimal numeric types, or the full grouping loop. Those are frame
conditions because the patch does not alter their branches, except that grouping
on the single integer digit `0` is observationally unchanged.

## Formal Claims

The K formal core is in:

- `fvk/mini-numberformat.k`
- `fvk/numberformat-spec.k`

Claim C1: `formatDecimal(pos, false, -200, 1, 2, true)` reaches
`FixedZero(pos, 2)`.

Claim C2: any zero-valued `Decimal` with `N >= 0` reaches
`FixedZero(SIGN, N)`.

Claim C3: any nonzero `Decimal` with `N >= 0`, `EXP < 0`, and
`EXP + LEN <= -N` reaches `FixedZero(SIGN, N)`.

Claim C4: any nonzero cutoff `Decimal` that is not smaller than the displayable
decimal width reaches `Scientific`, preserving the cutoff frame condition.

## Adequacy Audit

The formal claims match the intent spec for the audited domain:

- C1 directly covers the reported boundary example.
- C2 covers the V1 audit gap for zero values.
- C3 generalizes the prompt's "smaller in absolute size" requirement using the
  `Decimal.as_tuple()` representation.
- C4 prevents the proof from over-claiming that all cutoff values should become
  fixed notation.

Residual limitation: the `.k` model abstracts Python strings and Decimal
subclass construction. That is acceptable for this audit because the property
under verification is the branch/output shape (`FixedZero` versus `Scientific`),
but it remains part of the trusted base until machine-checked against a richer
Python semantics.

## Compatibility Audit

Public function signature: unchanged.

Public call shape: unchanged.

Virtual dispatch/subclass concern: `Decimal` subclasses can customize
`__format__()`. V2 keeps the normal non-cutoff fixed-format path unchanged and,
when the cutoff shortcut must synthesize a zero value, attempts to format a zero
of the same subclass. If that construction is not supported, V2 falls back to
the plain zero string rather than failing the formatting call.
