# Baseline Notes

## Root cause

`Colormap.__call__` copies integer inputs into `xa` without changing their
dtype. The method then uses `xa` as indices into a lookup table whose final
three entries are reserved for under-range, over-range, and bad values. Those
reserved indices are `self.N`, `self.N + 1`, and `self.N + 2`.

For the default `N == 256`, the largest reserved index is 258, which cannot be
represented by a `uint8` input array. Assigning those Python integers into a
`uint8` `xa` triggers NumPy 1.24 out-of-bound integer conversion deprecation
warnings. It can also lose the intended sentinel value by wrapping it into the
smaller dtype.

## Files changed

`repo/lib/matplotlib/colors.py`

Added a targeted promotion step for integer input arrays in
`Colormap.__call__`: if the current integer dtype cannot represent
`self._i_bad`, the largest sentinel index, `xa` is cast to the promoted dtype
needed to hold that value before assigning under, over, and bad sentinels.
This preserves the existing float handling and leaves integer arrays with
already-wide-enough dtypes unchanged.

## Assumptions and alternatives considered

I assumed the correct behavior is that `xa` should hold actual lookup-table
indices, including the special entries at the end of the table, rather than
relying on NumPy overflow behavior. This follows the issue discussion's point
that the lookup table has `N + 3` entries and `xa` needs to be able to index
them.

I considered applying modulo arithmetic to the sentinel values before
assignment, because that would reproduce the old overflow behavior exactly.
I rejected it because it would keep mapping bad, under, or over values to
ordinary colors for small integer dtypes instead of using the dedicated
lookup-table entries.

I also considered always casting integer inputs to the platform `int` dtype.
I rejected that as broader than necessary: the implemented fix only casts when
the existing dtype cannot store the sentinel index.
