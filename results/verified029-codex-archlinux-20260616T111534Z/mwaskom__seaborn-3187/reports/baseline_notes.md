# Baseline Notes

## Root cause

Numeric legend entries were formatted from Matplotlib formatter tick labels only. When `ScalarFormatter` decides to use an offset or scientific multiplier, that information is stored separately as formatter offset text returned by `get_offset()`. Seaborn used the formatted tick labels without also reading this offset, so large values could appear in legends as small mantissas such as `2`, `3`, or `4` with no indication that they should be interpreted with a `1e6` multiplier.

The issue appeared in both legend code paths:

- The objects API built continuous semantic legends in `ContinuousBase._setup` by calling `axis.major.formatter.format_ticks(locs)` and storing those labels directly.
- The classic relational API built brief numeric legends through `locator_to_legend_entries`, which manually called `formatter.set_locs(raw_levels)` and then formatted each level, again without including `formatter.get_offset()`.

## Files changed

- `repo/seaborn/utils.py`: added `_add_formatter_offset`, a small helper that appends non-empty formatter offset text to legend labels. `locator_to_legend_entries` now uses it after formatting brief numeric legend levels, so `scatterplot`, `lineplot`, and `relplot` legends retain large-number offset information.
- `repo/seaborn/_core/scales.py`: imported `_add_formatter_offset` and applied it to continuous semantic legend labels after `format_ticks`. This covers the objects API path used by `seaborn.objects`.

## Assumptions and alternatives

I assumed the safest minimal fix is to make the displayed legend labels self-contained whenever a formatter reports offset text. That keeps ordinary numeric legends unchanged because `get_offset()` returns an empty string when no offset is active.

I considered putting the offset only in the legend title or subtitle, which would more closely mirror how Matplotlib axes show offset text separately from tick labels. I rejected that as the primary fix because Seaborn has two legend assembly systems with different title/subtitle handling, and classic legends expose their semantic values as label text. Appending the offset to each affected label is narrower, works for both code paths, and avoids changing legend grouping or title behavior.

No tests or project code were run, per the benchmark instructions.
