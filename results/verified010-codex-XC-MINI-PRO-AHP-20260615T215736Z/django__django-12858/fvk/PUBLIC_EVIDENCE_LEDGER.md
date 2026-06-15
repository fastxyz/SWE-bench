# PUBLIC_EVIDENCE_LEDGER.md

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| I-001 | `benchmark/PROBLEM.md` | "`models.E015` is raised when ordering uses lookups that are not transforms." | Accept registered final lookup suffixes in ordering validation. |
| I-002 | `benchmark/PROBLEM.md` | Reported false positive for `supply__product__parent__isnull`. | No `models.E015` for the reported path. |
| I-003 | `benchmark/PROBLEM.md` | Both ascending and descending `order_by()` examples are shown. | Leading `-` must not change validity. |
| I-004 | Existing source behavior | `_check_ordering()` already accepts registered transforms with `get_transform()`. | Preserve transform acceptance. |
| I-005 | Existing invalid-ordering behavior | Missing fields and related fields are reported as `models.E015`. | Preserve invalid-path rejection. |
| I-006 | Check framework shape | `_check_ordering()` is a classmethod check returning `checks.Error` entries. | Preserve API shape and error type. |
