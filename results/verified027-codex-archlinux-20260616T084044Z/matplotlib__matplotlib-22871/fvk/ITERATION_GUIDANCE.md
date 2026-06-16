# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change in `repo/lib/matplotlib/dates.py`.

Reasoning:

- F-001 and PO-001 show that V1 addresses the reported family: month-level
  ticks without January keep `show_offset=True` and therefore render the year
  through `offset_formats[1]`.
- F-002 and PO-002 show that month-level ranges with January preserve the
  existing concise behavior.
- F-003, F-004, PO-004, PO-005, PO-006, and PO-007 show that the change is
  narrowly framed around the defective offset-suppression condition.

## No Additional Source Edits

No FVK finding justifies a new source edit in this pass.

- F-005 identifies an empty-input robustness question, but it is outside the
  issue intent and existed before V1.
- F-006 identifies proof scope limits, not a production-code defect.

## Suggested Tests For A Future Test-Enabled Pass

Do not add or edit tests in this benchmark task. In a normal development pass,
add a regression test for:

- A same-year month-level tick sequence after January with no January tick.
- `show_offset=True`.
- Expected offset: the year of the ticks, e.g. `2021`.

Keep existing offset tests until the emitted K commands are actually
machine-checked.

