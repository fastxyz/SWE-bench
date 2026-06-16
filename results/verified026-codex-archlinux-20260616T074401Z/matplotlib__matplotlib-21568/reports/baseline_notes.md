## Root Cause

Datetime formatters that opt into TeX rendering pass their formatted strings
through `matplotlib.dates._wrap_in_tex`. That helper wraps numeric and
punctuation portions in TeX math mode via `\mathdefault{...}` and previously
only protected dashes by rewriting `-` to `{-}`.

Regular spaces inside TeX math mode are ignored, so a formatted datetime such
as `2020-01-01 00:00` can render as if the date and time are adjacent. Colons
also remain math punctuation and can receive TeX math spacing instead of
literal text spacing. The result is unclear datetime tick labels when
`text.usetex` is enabled.

## Files Changed

`repo/lib/matplotlib/dates.py`

Updated `_wrap_in_tex` so TeX-wrapped datetime labels also protect colons as
`{:}` and convert literal spaces to `\;`. This preserves visible separation
between date and time fields while retaining the existing behavior that keeps
alphabetic date fragments, such as month names, outside `\mathdefault`.

`reports/baseline_notes.md`

Added this required task report.

## Assumptions and Alternatives

I assumed the bug is in TeX wrapping of already-formatted datetime labels, not
in date locator selection or layout. The reproduction and issue hints point to
spacing within tick label text, and `_wrap_in_tex` is the common path used by
`DateFormatter`, `AutoDateFormatter`, and `ConciseDateFormatter` when TeX is
enabled.

I considered replacing `_wrap_in_tex` with the exact monkey-patch from the
issue comment, which wraps the whole label in one `\mathdefault{...}` block.
I rejected that broader rewrite because the existing helper deliberately
splits alphabetic fragments out of math mode, preserving upright text for
month names and other words. Extending the existing punctuation and space
protection is the narrower fix for the reported collapse.

I did not modify tests and did not run tests or project code, per the task
constraints.
