# FVK Specification: ConciseDateFormatter Month Offset

Status: constructed for audit, not machine-checked.

## Scope

The audited unit is `matplotlib.dates.ConciseDateFormatter.format_ticks`,
specifically the level-selection and offset-selection behavior changed by V1 in
`repo/lib/matplotlib/dates.py`.

The formal core models the offset decision after tick datetimes have been
converted into year/month/day/hour/minute/second fields. It treats
`num2date`, `numpy.unique`, and `datetime.strftime` as trusted library
operations and models their relevant observable results symbolically:

- `level` is the precision level selected by the existing algorithm.
- `hasJanuary` means at least one visible tick at month-level has month `1`.
- `year(Y)` represents applying the default month-level offset format `%Y` to
  a same-year tick list whose year is `Y`.

This abstraction is property-complete for the reported defect because the
defect is exactly whether `offset_string` is empty or contains the year when
month-level labels have no January tick.

## Intent-Only Contract

1. For a sub-year plot where January is not included in the visible x-axis
   month ticks, the year must still be displayed in the offset.
2. `ConciseDateFormatter` should stay concise but complete: tick labels and
   offset together should provide the missing date context.
3. At month level, January ticks normally provide the year through
   `zero_formats[1]` (`%Y` by default), so the offset is redundant when such a
   tick is visible.
4. If `show_offset=False`, the formatter must not display an offset.
5. Year-level labels already display years, so the offset remains redundant.
6. Levels finer than months keep the existing offset behavior.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "When I plot < 1 year and January is not included in the x-axis, the year doesn't show up anywhere." | The no-January, sub-year month-level family is in domain. | Encoded by PO-001. |
| E2 | prompt | "I expect the year \"2021\" to show in the offset, to the right of the x-axis" | For the reproducer family, month-level offset must be `%Y`, not empty. | Encoded by PO-001. |
| E3 | docs | "`ConciseDateFormatter` ... compact as possible, but still be complete." | Completeness is a formatter invariant, not merely a cosmetic preference. | Encoded by PO-001 to PO-004. |
| E4 | docs | "if most ticks are months, ticks around 1 Jan 2005 will be labeled \"Dec\", \"2005\", \"Feb\"" | January month ticks can carry year context through `zero_formats[1]`. | Encoded by PO-002. |
| E5 | docs | "Combined with the tick labels this should completely specify the date." | The offset supplies date context that labels omit. | Encoded by PO-001 and PO-004. |
| E6 | public tests | `test_concise_formatter_show_offset(... weeks=26 ...) == ''` for a January-origin range. | Existing January-visible month-level behavior should remain unchanged. | Encoded by PO-002. |
| E7 | public tests | Existing hour/day/minute/second offset expectations. | Finer levels must keep previous offset behavior. | Encoded by PO-004 and PO-007. |
| E8 | API | `show_offset : bool` controls whether the offset is shown. | User suppression must still win. | Encoded by PO-005. |

## Domain Assumptions

- `format_ticks` receives a non-empty sequence of tick values from a locator.
- Each tick value is convertible by `num2date` into a valid datetime.
- The reported no-January, sub-year case is a single-calendar-year tick list;
  a continuous date range shorter than one year that excludes January cannot
  cross a January boundary.
- The formal proof is partial correctness over the decision core. It does not
  prove Matplotlib drawing, locator placement, timezone conversion, or
  termination.

## Formal Claims

The K claims are in `fvk/concise-date-formatter-spec.k`.

- PO-001: month-level, `show_offset=True`, no January tick, same-year list
  with year `Y` reaches `year(Y)`.
- PO-002: month-level, `show_offset=True`, at least one January tick reaches
  `noOffset`.
- PO-003: year-level, `show_offset=True` reaches `noOffset`.
- PO-004: levels 2 through 5, `show_offset=True` reach their existing
  level-specific offset.
- PO-005: any level 0 through 5 with `show_offset=False` reaches `noOffset`.
- PO-006: label-format selection is frame-preserved by moving `zerovals`
  before the level-selection loop.
- PO-007: TeX wrapping remains frame-preserved.
- PO-008: the proof is constructed but not machine-checked in this session.

