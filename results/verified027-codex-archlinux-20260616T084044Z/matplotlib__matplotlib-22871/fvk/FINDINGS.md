# FVK Findings

Status: findings from `/formalize` and `/verify`, constructed but not
machine-checked.

## F-001: V1 fixes the reported no-January month-level offset bug

Classification: code bug fixed by V1.

Input family: non-empty same-year month-level tick lists with
`show_offset=True`, no visible January tick, default `offset_formats[1] ==
"%Y"`. The reproducer's visible ticks are in 2021 after January.

Observed before V1: the selected level is `1`, the old condition
`if level < 2: show_offset = False` suppresses the offset, and non-January
month labels use `%b`, so the year is absent from both labels and offset.

Expected: the offset is the year, e.g. `2021`.

V1 result: level `1` with no January tick does not suppress `show_offset`; the
existing offset-rendering branch formats the last tick with
`offset_formats[1]`, producing the year.

Trace: E1, E2, E3, E5; PO-001.

## F-002: V1 preserves the January month-level behavior

Classification: compatibility confirmed.

Input family: month-level tick lists with `show_offset=True` and at least one
visible January tick.

Observed before V1: offset is suppressed; the January tick is formatted with
`zero_formats[1]`, which is `%Y` by default.

Expected: preserve this concise behavior because the year is already present
in a tick label.

V1 result: the condition `level == 1 and hasJanuary` still suppresses the
offset.

Trace: E4, E6; PO-002.

## F-003: Finer precision levels are unchanged

Classification: compatibility confirmed.

Input family: selected levels 2 through 5 with `show_offset=True`.

Observed before V1: offset is shown using `offset_formats[level]`.

Expected: no change; the issue is specific to month-level offset suppression.

V1 result: the new condition only changes level `1` without January. Levels
2 through 5 still leave `show_offset` unchanged and therefore use the existing
offset branch.

Trace: E7; PO-004, PO-007.

## F-004: Explicit `show_offset=False` remains authoritative

Classification: compatibility confirmed.

Input family: any selected level 0 through 5 with `self.show_offset == False`.

Observed before V1: no offset is displayed.

Expected: no offset is displayed because the public API explicitly asks for
that.

V1 result: local `show_offset` starts from `self.show_offset`; the new code can
only set it to `False`, never to `True`.

Trace: E8; PO-005.

## F-005: Empty `values` remains outside the audited intent domain

Classification: residual precondition / not repaired in this issue pass.

Input: `format_ticks([])`.

Observed from static inspection: the implementation builds an empty array and
then indexes it as a two-dimensional tick matrix. This behavior existed before
V1 and is not described by the issue, docs excerpt, or public offset tests
used as evidence here.

Expected under this FVK spec: non-empty locator-produced tick values.

Decision: no source edit. Treating empty ticks as a separate API robustness
question avoids broadening this issue fix beyond the public no-January offset
intent.

Trace: domain assumptions in `SPEC.md`; PO-008.

## F-006: Formal proof scope is intentionally smaller than real Matplotlib

Classification: proof capability gap / trusted base.

The K model proves the offset decision core. It does not model real Python,
NumPy arrays, datetime conversion, timezone behavior, Matplotlib rendering, or
the actual `strftime` implementation. Those are trusted library/framework
facts for this audit.

Decision: keep tests and do not claim machine-checked verification. The proof
is useful for auditing the branch logic that produced the defect.

Trace: PO-008.

