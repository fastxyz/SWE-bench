# Public Evidence Ledger

Status: constructed, not machine-checked.

This file mirrors the ledger in `SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | prompt / public issue | `dateformat.y() doesn't support years < 1000.` | Correct `y` for years below 1000. |
| E-002 | prompt / public issue | Django returns `"3"` for year 123; Python and PHP return `23`. | Year 123 must format as `"23"`. |
| E-003 | prompt / public issue | The issue names similar matters for years like 99 and 9. | Cover the small-year boundary family. |
| E-004 | docs | `y` is `Year, 2 digits.` | Output must have exactly two digits. |
| E-005 | docs | Django date syntax is similar to PHP `date()`. | PHP-style two-digit `y` semantics are relevant. |
| E-006 | public test | Year 1979 with `y` returns `"79"`. | Preserve ordinary-year behavior. |
| E-007 | implementation | V1 returns `'%02d' % (self.data.year % 100)`. | Candidate mechanism to prove, not an independent oracle. |
