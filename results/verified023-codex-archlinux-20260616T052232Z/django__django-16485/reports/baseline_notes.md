## Root cause

`floatformat()` computes a custom `decimal.Context` precision before calling
`Decimal.quantize()`. For zero values with an explicit fractional exponent, such
as `"0.00"` or `Decimal("0.00")`, `m` is false and the code adds the negative
Decimal exponent to the digit count. That can make the computed precision zero
or negative when `arg` is `0`. Passing `prec=0` to `decimal.Context` raises
`ValueError: valid range for prec is [1, MAX_PREC]` before formatting can
continue.

## Changed files

`repo/django/template/defaultfilters.py`

Clamped the computed precision with `max(1, ...)` before constructing the
`decimal.Context`. This preserves the existing precision calculation for all
positive results while ensuring zero-valued Decimals with trailing decimal
places still use the minimum valid Decimal context precision.

## Assumptions and alternatives considered

I assumed `floatformat("0.00", 0)` and `floatformat(Decimal("0.00"), 0)` should
follow the existing `arg=0` behavior and format as a rounded integer value
instead of returning the original input or an empty string.

I considered special-casing zero values before quantization, but rejected that
because it would duplicate the existing rounding and formatting path, including
localization and grouping handling. I also considered changing the `units`
calculation, but that has broader implications for nonzero Decimal precision.
Clamping only the final precision is the smallest targeted change and matches
`decimal.Context`'s minimum precision requirement.
