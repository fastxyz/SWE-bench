# FVK Spec: `floatformat()` Zero-Decimal Precision

Status: constructed, not machine-checked.

## Scope

Production code under audit:
`repo/django/template/defaultfilters.py`, function `floatformat()`, specifically
the Decimal precision calculation before `Decimal.quantize()`.

The FVK proof models the reported crash path: finite zero-valued Decimal inputs
with explicit scale, such as `"0.00"` and `Decimal("0.00")`, and integer
precision argument `0`. The model also captures the frame condition for
negative precision zero inputs.

There are no loops in this audited slice. The proof obligations are straight
reachability claims over a small abstract K semantics.

## Intent Summary

The public issue says the two calls `floatformat('0.00', 0)` and
`floatformat(Decimal('0.00'), 0)` raise `ValueError` because Decimal context
precision is outside the valid range. Django's template filter docs state that
precision `0` is a public way to round to integer form. For a zero input, that
integer-form result is `"0"`.

## Public Evidence

The standalone public evidence ledger is in
`fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E-01/E-02: the issue makes zero decimals with scale and `arg=0` in-domain.
- E-03: docs make precision `0` part of the public contract.
- E-06: the reported exception identifies Decimal's minimum context precision
  as the failed side condition.
- E-07: existing public tests provide frame evidence for negative rounded zero
  and invalid non-empty arguments.

## Formal Model

The formal core is:

- `fvk/mini-floatformat.k`
- `fvk/floatformat-spec.k`

The abstraction keeps the defect axis visible. A zero Decimal with scale `S`
has coefficient digit length `1` and exponent `-S`, so the pre-fix raw precision
for nonnegative precision `P` is `P + 2 - S`. The V1 code computes
`max(1, P + 2 - S)`.

## Claims

- C-01: for all `P >= 0` and `S >= 0`, `max(1, P + 2 - S) >= 1`.
- C-02: for all `S >= 0`, formatting zero at precision `0` returns `"0"`.
- C-03: for all `P < 0`, the zero-valued path returns `"0"` before Decimal
  context precision is constructed.

## Adequacy Gate

`fvk/INTENT_SPEC.md`, `fvk/FORMAL_SPEC_ENGLISH.md`,
`fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` are non-empty and
agree for the reported zero-decimal precision path.

The proof does not claim to verify all of `floatformat()` against full Python,
Decimal, localization, or template semantics. That boundary is recorded in
`fvk/FINDINGS.md` and does not justify any additional source change.
