# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Fix parse_duration() for some negative durations" | The candidate must change behavior for an in-domain negative standard duration family. | Encoded in SPEC and claims. |
| E2 | prompt | The old `standard_duration_re` allows `-?` on hours, minutes, and seconds. | Component-local signs are the suspected root cause. | Encoded as V0 finding, not preserved. |
| E3 | prompt | "`parse_duration('-00:01:01')` => plus 61 seconds" followed by "I'd expect a leading minus sign to negate the entire value so they would be minus 61 seconds." | A leading `-` on a no-day standard time negates the whole time. | Encoded in PO-1 and K claims. |
| E4 | prompt | "I think the second and fourth examples are invalid. I don't think a minus sign after a colon is valid." | Signs after colons are invalid in standard format. | Encoded in PO-2 and K claims. |
| E5 | prompt | "everything but a leading - seems like an invalid value that happened to work" | Do not preserve internal component signs from legacy behavior. | Encoded in findings and proof obligations. |
| E6 | docs | `parse_duration()` expects `"DD HH:MM:SS.uuuuuu"` or ISO 8601 or PostgreSQL day-time intervals. | Preserve accepted positive standard, ISO 8601, and PostgreSQL format families. | Encoded as frame obligations. |
| E7 | public test | `parse_duration(format(delta)) == delta` for negative `timedelta(days=-4, minutes=15, seconds=30)`. | Signed day strings emitted by Python remain valid and keep signed-day semantics. | Encoded in PO-3. |
| E8 | public test | Existing tests expect `-15:30` as `minutes=-15, seconds=30` and `-1:15:30` as `hours=-1, minutes=15, seconds=30`. | This conflicts with E3 and is suspect legacy behavior. | Recorded as Finding F2; not used as spec. |
| E9 | source | `DurationField` and `forms.DurationField` call `parse_duration(value)` and accept `None` as invalid. | Signature and return shape must remain unchanged. | Encoded in compatibility audit. |
