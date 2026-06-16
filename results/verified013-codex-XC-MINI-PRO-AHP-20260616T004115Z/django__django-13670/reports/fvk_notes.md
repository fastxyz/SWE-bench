# FVK Notes

## Decision

V1 stands unchanged.

## Trace to Findings and Obligations

The reported defect is the legacy string-slicing behavior for small years.
Finding F-001 identifies the concrete failing input `Y = 123`; OBL-003 requires
the last two year digits, and the V1 expression `'%02d' % (year % 100)`
discharges that obligation by deriving `123 % 100 == 23`.

The audit treated the issue as a family of boundary cases, not a single example.
Finding F-002 and OBL-004 cover years `1..99`, `100..999`, and rollover cases
such as `1000`. The same modulo-plus-width-two formula covers all of them, so no
additional source edit was justified.

I kept the V1 implementation instead of refactoring to `zfill()` because
OBL-003 is naturally numeric: compute `year % 100`, then render it to width two.
That also preserves ordinary years, as shown by F-003 and OBL-005 for
`1979 -> "79"`.

I did not change `DateFormat.Y()`, other formatter methods, docs, or public
dispatch. F-004, OBL-006, and OBL-007 show the public API and unrelated tokens
are frame conditions, and the source diff already satisfies them.

I did not edit tests or run tests, Python, `kompile`, or `kprove`. F-005 and
OBL-008 record the honesty gate: the proof is constructed, not machine-checked,
and test-removal recommendations are conditional on a future `kprove` result.
