# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent match | Audit |
| --- | --- | --- |
| `VALUES-MARKS` | Pass | Matches the requirement that `values()` restore dict-shaped results. |
| `VALUES-LIST-TUPLE-MARKS` | Pass | Covers the public `values_list()` tuple variant concern. |
| `VALUES-LIST-FLAT-MARKS` | Pass | Covers the public flat values-list variant concern. |
| `VALUES-LIST-NAMED-MARKS` | Pass | Covers the public named values-list variant concern. |
| `ASSIGN-MARKED-SELECT` | Pass | Matches the documented `qs.query = query` restoration workflow. |
| `ASSIGN-UNMARKED-SELECT` | Pass with boundary | Prevents the reported model-iteration crash for selected queries. It intentionally does not claim exact old/unmarked values-list recovery. |
| `ASSIGN-NONSELECT-FRAME` | Pass | Preserves existing non-selected query assignment behavior; no public intent requires a change there. |

No formal claim is candidate-only or legacy-only. The only boundary is exact recovery of unmarked values-list mode, recorded as F4/PO7.

