# Intent Spec

Status: intent-only, written before accepting V1 as correct.

## Required Behaviors

1. `floatformat()` must handle finite zero-valued decimal inputs with an explicit
   fractional scale, including `"0.00"` and `Decimal("0.00")`.
2. Calling `floatformat(value, 0)` is in-domain and rounds the value to integer
   form. For a zero value, the required result is `"0"`.
3. The fix must remove the reported `ValueError` from `decimal.Context`
   construction on zero-valued decimals.
4. Existing documented suffix behavior (`g` for grouping, `u` for disabling
   localization) and negative-precision zero behavior are frame conditions:
   this issue does not justify changing them.
5. The public function signature and return shape must remain unchanged.

## Domain

The proof domain for this FVK pass is the reported precision path:
finite numeric inputs that parse as Decimal zero with scale `S >= 0`, and
integer precision argument `P`, especially `P = 0`.

Full `floatformat()` behavior for nonzero Decimal rounding, float fallback,
localization, grouping, infinity, and NaN remains covered by Django's existing
implementation and tests, but is outside this mini-semantics proof.
