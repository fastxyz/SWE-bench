# Baseline Notes

## Root cause

`ConciseDateFormatter.format_ticks` chooses a label precision level and then
decides whether the axis offset is redundant. For year-level and month-level
ticks it always disabled the offset. Month-level labels only show the year when
a visible tick falls in January, because January uses the zero-format
(`%Y` by default). If the plotted range is less than a year and starts after
January, every tick can be formatted only as a month name while the offset is
also suppressed, so the year is not displayed anywhere.

## Changed files

`repo/lib/matplotlib/dates.py`

The offset-suppression condition in `ConciseDateFormatter.format_ticks` now
keeps the offset enabled for month-level ticks unless one of the visible month
ticks is January. Year-level ticks still suppress the offset because the tick
labels themselves are years. Month-level ranges that include January keep the
previous behavior because January is already formatted with the zero-format,
which provides the year.

`reports/baseline_notes.md`

Added this required report describing the root cause, the source edit, and the
reasoning behind the chosen fix.

## Assumptions and alternatives

I assumed the intended concise formatting behavior is to suppress the offset
only when the displayed tick labels already provide the higher-level date
context. This matches the existing default where January month ticks display
the year.

I considered changing the default month label format to always include the
year, but rejected that because it would make all month-level axes less
concise and would affect many existing labels. I also considered forcing the
first visible month tick to use the year format when January is absent, but
that would replace the month label with a year and hide the month at that tick.
Using the existing offset preserves the month labels while supplying the
missing year context.
