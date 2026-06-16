# Public Evidence Ledger

This ledger mirrors the evidence table in `SPEC.md`.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "When I plot < 1 year and January is not included in the x-axis, the year doesn't show up anywhere." | No-January month-level ranges are in scope. |
| E2 | prompt | "I expect the year \"2021\" to show in the offset" | Offset must contain the year for the reproducer family. |
| E3 | docs | "compact as possible, but still be complete" | Completeness is a formatter invariant. |
| E4 | docs | January month tick example labels `"2005"` | January can provide year context through zero-format. |
| E5 | docs | Offset plus tick labels should specify the date | Offset supplies omitted higher-level context. |
| E6 | public tests | January-origin 26-week offset expectation is empty | Preserve January-visible month-level behavior. |
| E7 | public tests | Existing day/hour/minute/second offset expectations | Preserve finer-level offset behavior. |
| E8 | API | `show_offset` parameter | User suppression remains authoritative. |

