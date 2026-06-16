# Findings

Status: constructed from public evidence and source inspection only.

## F-001: Original code loses Decimal precision

Classification: code bug fixed by V1.

Input: `Decimal('42.12345678901234567890')` with argument `20`.

Observed before V1: the issue reports `42.12345678901234400000`.

Expected: `42.12345678901234567890`.

Cause: `repr(Decimal(...))` is not a decimal numeric literal for
`Decimal(input_val)`, so the old code entered the fallback
`Decimal(str(float(text)))`. That fallback loses precision through binary
float conversion.

Related obligations: PO-1, PO-2, PO-3.

## F-002: V1 discharges the Decimal precision obligation

Classification: confirmation; no new source edit required.

Input family: finite `Decimal` input `D` with normalized integer argument `P`.

V1 behavior by source inspection: the `isinstance(text, Decimal)` branch sets
`d = text`, so the existing quantize/render path receives the exact Decimal.

Expected: rounding/rendering uses exact `D`, not a float approximation.

Related obligations: PO-2, PO-3.

## F-003: Broad `repr()` to `str()` conversion is not justified

Classification: rejected alternative.

Candidate change: replace the initial conversion for all values with
`input_val = str(text)`.

Reason rejected: the public issue is Decimal-specific, and public tests frame
existing non-Decimal behavior. A broad change could alter numeric-string and
custom-object dispatch beyond the reported defect. V1 instead changes only
existing `Decimal` instances.

Related obligations: PO-4, PO-5.

## F-004: Full localization and Decimal arithmetic are outside the mini-K model

Classification: proof capability boundary, not a code bug.

The `.k` artifacts model the precision route and pin the issue-point Decimal
rendering fact. They do not implement full Python `decimal.Decimal`,
`formats.number_format()`, locale separators, or SafeString behavior.

Recommended handling: keep existing integration/localization tests; only treat
test-removal recommendations as valid after running the emitted K commands in a
real environment and retaining separate integration coverage.

Related obligations: PO-3, PO-6.
