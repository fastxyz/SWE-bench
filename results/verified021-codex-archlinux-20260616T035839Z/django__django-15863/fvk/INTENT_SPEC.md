# Intent Spec

Status: constructed from public evidence only; no tests or code were executed.

## Required behavior

I-1. `floatformat` must treat `Decimal` values as in-domain numeric inputs.
Evidence: the issue says "`floatformat` template filter may drop precision when
used for Decimal numbers"; public tests already call `floatformat(Decimal(...))`.

I-2. For finite `Decimal` input and an integer decimal-place argument, rounding
and formatting must be computed from the exact `Decimal` value, not from a
binary float approximation. For the issue value
`Decimal('42.12345678901234567890')` and argument `20`, the expected formatted
numeric string is `42.12345678901234567890`.

I-3. Existing documented `floatformat` behavior remains in force: no argument is
equivalent to `-1`; positive arguments show exactly that many decimal places;
negative arguments suppress decimal places only when no decimal part is present;
`g` forces grouping; `u` disables localization.

I-4. Non-numeric values that cannot be interpreted through the existing numeric
path remain outside the numeric formatting domain and return the established
empty result.

I-5. The public API shape must not change: `floatformat(text, arg=-1)` remains a
template filter with the same decorators and return protocol.

## Explicit non-goals

N-1. The public issue does not require changing all non-Decimal inputs from the
existing `repr()` conversion path to direct `str()` parsing.

N-2. This pass does not specify or repair undocumented argument forms such as an
empty string argument; those are outside the Decimal precision obligation.
