# Spec Audit

Status: adequacy comparison, constructed and not machine-checked.

| Formal Claim | Intent Entry | Adequacy Result | Notes |
| --- | --- | --- | --- |
| HTML-FORMATS-1D | INTENT 1, 2; ledger E1-E6 | Pass | The claim exactly captures that HTML must install `formats` before `iter_str_vals()` renders cells. |
| HTML-FORMATS-NO-ENTRY | INTENT 3 | Pass | The claim preserves columns not named in `formats`. |
| HTML-FORMATS-MULTICOL | INTENT 5; ledger E7 | Pass | The claim covers the second contributor to HTML data cells: split temporary columns. |
| Frame conditions | INTENT 4 | Pass | The formal English only frames fill-value and raw-HTML behavior; it does not over-specify full HTML serialization. |

No claim depends on the pre-fix HTML output as desired behavior. The issue's
shown full-precision HTML output is treated as SUSPECT legacy behavior because
the public issue identifies it as the bug.
