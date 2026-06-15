# Public Evidence Ledger

Status: constructed for FVK audit, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "django.utils.http.parse_http_date two digit year check is incorrect" | Audit `parse_http_date()` year expansion. | Encoded in `SPEC.md`, `http-date-spec.k`. |
| E2 | problem | "Recipients of a timestamp value in rfc850-date format, which uses a two-digit year, MUST interpret a timestamp that appears to be more than 50 years in the future as representing the most recent year in the past that had the same last two digits." | RFC850 two-digit years roll back one century only when the current-century candidate is strictly beyond `current_year + 50`. | Encoded in PO-001 through PO-003. |
| E3 | problem | "Current logic is hard coded to consider 0-69 to be in 2000-2069, and 70-99 to be 1970-1999, instead of comparing versus the current year." | Reject fixed cutoff; threshold is relative to current year. | Encoded in PO-004 and Finding F-001. |
| E4 | public hint | "The check should be relative to the current year" | Current year is part of the postcondition, not a constant. | Encoded in PO-004. |
| E5 | public hint | "comment ... regarding the use of non-UTC today" | Use UTC current year, not local date. | Encoded in PO-005 and Finding F-002. |
| E6 | public hint | "Year is now checked in relation to current year, rolling over to the past if more than 50 years in the future" | Confirms strict rollover shape: current-year-relative candidate, then past rollover. | Encoded in PO-002 and PO-003. |
| E7 | code docstring | "The three formats allowed by the RFC are accepted" | Preserve RFC1123, RFC850, and asctime recognition. | Frame condition PO-006. |
| E8 | code docstring | "Return an integer expressed in seconds since the epoch, in UTC." | Return type and UTC conversion behavior remain unchanged. | Frame condition PO-006. |
| E9 | public test | RFC1123/RFC850/asctime 1994 examples assert the same UTC timestamp. | Preserve existing valid-date parsing outside the two-digit rollover. | Frame condition PO-006. |
| E10 | public test | `Sun Nov  6 08:49:37 0037` expects 2037 in the checked-in test. | Compatibility evidence for keeping the `year < 100` branch broad. | Finding F-004 documents the provenance. |
| E11 | code/callsites | `parse_http_date_safe()` and public callers consume integer or `None`; static view catches `ValueError`/`OverflowError`. | No signature, exception-shape, or return-shape change. | Compatibility audit passed. |

