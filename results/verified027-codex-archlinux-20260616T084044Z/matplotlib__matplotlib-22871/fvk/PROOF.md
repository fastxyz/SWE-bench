# FVK Proof

Status: constructed, not machine-checked.

## Target

The proof targets the offset-decision core of
`ConciseDateFormatter.format_ticks`. The source code first selects a precision
`level`, then conditionally suppresses the offset, then renders the offset if
`show_offset` remains true.

The mini semantics in `mini-python-date.k` abstracts the relevant decision as:

```text
offsetFor(level, showOffset, hasJanuary, year)
```

where `hasJanuary` is exactly
`np.any(tickdate[:, level] == zerovals[level])` in the month-level case.

## Constructed Claims

The formal claims are in `concise-date-formatter-spec.k`.

- C-001 proves PO-001: `offsetFor(1, true, false, Y) => year(Y)`.
- C-002 proves PO-002: `offsetFor(1, true, true, Y) => noOffset`.
- C-003 proves PO-003: `offsetFor(0, true, H, Y) => noOffset`.
- C-004 proves PO-004: `offsetFor(L, true, H, Y) => formatted(L, Y)` for
  `2 <= L <= 5`.
- C-005 proves PO-005: `offsetFor(L, false, H, Y) => noOffset` for
  `0 <= L <= 5`.

## Proof Sketch

For PO-001, instantiate the source branch with `level == 1`,
`show_offset == True`, and no January tick. The V1 condition
`level == 0 or (level == 1 and hasJanuary)` is false, so `show_offset` remains
true. The existing offset branch then writes
`tickdatetime[-1].strftime(offsetfmts[1])`. For a same-year sub-year list and
the default `%Y` month-level offset format, this is the expected year, e.g.
`2021`.

For PO-002, instantiate `level == 1`, `show_offset == True`, and
`hasJanuary == True`. The V1 condition is true, so `show_offset` becomes false
and `offset_string` is set to the empty string. The label loop is unchanged and
the January tick satisfies `tickdate[nn][1] == zerovals[1]`, so it uses
`zero_formats[1]`, `%Y` by default.

For PO-003, instantiate `level == 0`. The V1 condition is true independently
of `hasJanuary`, so the offset is empty. This preserves year-level behavior,
where tick labels already use `formats[0]`.

For PO-004, instantiate `level >= 2`. The V1 condition is false, so if
`self.show_offset` was true, the offset-rendering branch is reached exactly as
before and uses `offset_formats[level]`.

For PO-005, instantiate `self.show_offset == False`. The local `show_offset`
starts false and the V1 code never assigns true, so the empty-offset branch is
reached for every level.

PO-006 and PO-007 are frame arguments: V1 moved the `zerovals` definition
before its first use and changed only the offset-suppression predicate. The
label-format loop, second/microsecond trimming, and TeX wrapping branches are
unchanged.

## Adequacy Gate

The formal English claims match the public intent:

- The issue requires a year offset for no-January, sub-year month ticks.
  C-001 states exactly that decision.
- The docs and public tests justify suppressing offset when January already
  supplies the year. C-002 preserves that behavior.
- No claim relies on hidden tests, upstream patches, benchmark results, or
  evaluator feedback.

Residual scope limits are recorded as findings F-005 and F-006.

## Commands For Later Machine Checking

Do not run these in this session. They are recorded for a later environment
with K installed.

```sh
cd fvk
kompile mini-python-date.k --backend haskell
kast --backend haskell concise-date-formatter-spec.k
kprove concise-date-formatter-spec.k
```

Expected machine-check result after successful discharge: `#Top`.

## Test Recommendation

No tests are removed or modified. Because the proof is constructed but not
machine-checked, all existing tests should be kept. A focused regression test
would cover a same-year month-level range after January, with no January tick,
and assert that `ConciseDateFormatter.get_offset()` is the year.

