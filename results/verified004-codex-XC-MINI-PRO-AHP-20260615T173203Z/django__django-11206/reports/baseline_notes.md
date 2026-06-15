# Baseline Notes

## Root cause

`django.utils.numberformat.format()` sends `Decimal` values with more than 200
effective digits through scientific notation before the normal fixed-decimal
formatting logic runs. For very small decimals such as `Decimal('1e-200')`,
that cutoff is reached even when `decimal_pos` is supplied and the value would
be truncated to all zeroes by the fixed-decimal path.

The cutoff is still needed to avoid expanding huge `Decimal` values with
`'{:f}'.format()`, but the formatter can determine from the decimal tuple when
the first significant digit is beyond the requested number of decimal places.
In that case it can safely use a zero string and let the existing decimal
padding and grouping logic produce the final output.

## Files changed

`repo/django/utils/numberformat.py`

Added a narrow branch in the `Decimal` handling path. When `decimal_pos` is a
non-negative integer and the decimal's adjusted exponent is smaller than the
lowest displayable fractional position, the function now formats the value as
`0` or `-0` instead of using scientific notation. The rest of the function then
adds the requested decimal separator and trailing zeroes as before.

## Assumptions and alternatives considered

I treated `decimal_pos` as a truncation width, matching the existing formatter:
digits beyond `decimal_pos` are discarded rather than rounded. Therefore a
number whose first significant digit is past that width should format as zero.

I limited the change to small `Decimal` values with a supplied non-negative
`decimal_pos`. Very large values and small values without `decimal_pos` continue
to use the existing scientific-notation fallback so the memory-protection
behavior remains intact.

I considered bypassing the 200-digit cutoff for all `Decimal` values when
`decimal_pos` is supplied, but rejected that because it could require expanding
arbitrarily long fixed strings. The implemented check handles the reported
wrong result without removing the cutoff.
