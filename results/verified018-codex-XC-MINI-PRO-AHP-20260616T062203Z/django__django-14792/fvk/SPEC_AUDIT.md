# Spec Audit

Status: constructed, not machine-checked.

| Formal obligation | Intent source | Result | Notes |
| --- | --- | --- | --- |
| Signed IANA names classify as `noDelta`. | E1, E3, E4 | Pass | Directly covers the reported `Etc/GMT-10` regression. |
| PostgreSQL preserves non-offset names. | E1, E4 | Pass | Prevents `Etc/GMT-10` -> `Etc/GMT+10`. |
| PostgreSQL reverses numeric offset signs. | E2 | Pass | Preserves existing offset behavior. |
| MySQL and Oracle preserve non-offset names. | E3, E4 | Pass | Prevents suffix truncation of `Etc/GMT-10`. |
| MySQL and Oracle strip `UTC` only for numeric offsets. | E2, existing fixed-offset tests in source context | Pass | Keeps fixed-offset `datetime.timezone` behavior. |
| SQLite parses offsets only for fixed-offset forms. | E5 | Pass | Covers same-root sign-search bug. |
| Database engine timezone-table behavior. | None in code; backend feature-dependent | Out of formal scope | Recorded as residual risk, not used to justify source behavior. |

No formal claim is candidate-derived only. The V2 tightening of `_split_tzname_delta()` was added because the V1 prefix-only classifier was broader than the intent-derived fixed-offset family.
