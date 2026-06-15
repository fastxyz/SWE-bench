# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "TIME_ZONE value in DATABASES settings is not used when making dates timezone-aware on MySQL, SQLite, and Oracle." | Repair must apply to non-timezone-aware backends and use the database setting during datetime-aware SQL operations. | Encoded in `SPEC.md`, PO1-PO6. |
| E2 | problem | "The conversion should go from the database timezone tz2 to the django app one tz1." | Source timezone for SQL conversion is `connection.timezone_name`; target is current/explicit Django timezone. | Encoded in PO2-PO6 and K claims. |
| E3 | problem | "when tz1 == tz2, there should be no need to use CONVERT_TZ" | Equal source/target must be a no-op, especially for MySQL. | Encoded in PO2 and no-op K claims. |
| E4 | problem | Example SQL shows `DATE(CONVERT_TZ(field, 'UTC', 'Europe/Paris'))` as wrong for Paris-stored data. | The pre-fix hardcoded UTC source is suspect legacy behavior, not a spec. | Finding F-001. |
| E5 | docs/settings | Database `TIME_ZONE`: "time zone for datetimes stored in this database" and reads/writes local according to it when `USE_TZ` is true and backend lacks timezone support. | Stored naive values on MySQL/SQLite/Oracle must be interpreted in the connection timezone. | Encoded in INTENT 1 and PO1. |
| E6 | docs/querysets | `__date`: "When USE_TZ is True, fields are converted to the current time zone before filtering." | Date lookup target is current timezone. | Encoded in INTENT 3 and PO7. |
| E7 | docs/querysets | `datetimes()`: `tzinfo` defines timezone to which datetimes are converted prior to truncation. | Truncation paths share the same source-to-target obligation. | Encoded in PO7. |
| E8 | docs/database-functions | `Extract`: a `tzinfo` can be passed; active timezone changes extracted day/hour. | Extraction paths share the same source-to-target obligation. | Encoded in PO7. |
| E9 | docs/database-functions | `Trunc`: a `tzinfo` can be passed to truncate in a specific timezone. | Truncation paths must use requested timezone after source interpretation. | Encoded in PO7. |
| E10 | implementation | Existing adapt/read paths use `self.connection.timezone` for MySQL, SQLite, and Oracle `DateTimeField` values. | Implementation evidence that `connection.timezone_name` is the correct SQL source analogue. | Supports PO1-PO6; not used alone as intent. |
| E11 | compatibility audit | `datetime_*_sql()` public virtual method signatures remain unchanged in V1. | Public callers and backend overrides should remain compatible. | Encoded in PO8 and `PUBLIC_COMPATIBILITY_AUDIT.md`. |
