# Public Evidence Ledger

This mirrors the evidence entries in `fvk/SPEC.md`.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "SelectDateWidget can crash with OverflowError." | No uncaught overflow from user-controlled date components. | PO-001, F-001 |
| E-002 | prompt | "validation logic run in form.is_valid" | Malformed input should become validation failure, not server failure. | PO-001, PO-002 |
| E-003 | prompt | `datetime.date(int(y), int(m), int(d))` with user-controlled `y`, `m`, `d` | Complete-triple conversion exceptions must be handled. | PO-001, PO-002 |
| E-004 | implementation comment | "Return pseudo-ISO dates with zeros for any unselected values" | Preserve pseudo-ISO invalid complete-triple behavior. | PO-002 |
| E-005 | public tests | visible `test_value_from_datadict()` branch expectations | Preserve valid, invalid, blank, and fallback branches. | PO-003, PO-004, PO-005 |
| E-006 | public API shape | public widget method called by form binding and wrappers | Preserve signature and return protocol. | PO-006 |

