# Spec Audit

Status: adequacy audit, constructed but not machine-checked.

| Formal obligation | Intent entry | Result | Notes |
|---|---|---|---|
| `RESOLVE-POINT` | Intent 4 | Pass | Preserves existing point classification and does not affect the reported line flag. |
| `RESOLVE-AEQB-LINE` | Intent 1, 2, 3 | Pass | Directly encodes the issue's "not collapsed" edge-metadata requirement for the only branch where `ab` otherwise names the collapsed edge. |
| `RESOLVE-AEQC-LINE` | Intent 3 | Pass | `ab` already names the represented `A-B` line segment. |
| `RESOLVE-BEQC-LINE` | Intent 3 | Pass | `ab` already names the represented `A-B` line segment. |
| `RESOLVE-TRIANGLE` | Intent 4 | Pass | Non-degenerate decoded triangles remain triangles. |
| Query bridge: `LINE` uses `ab` | Intent 1, public source E5 | Pass | Both LatLon and XY shape query paths consume `scratchTriangle.ab` in their `LINE` `CONTAINS` branch. |
| No public API or test change | Intent 5 | Pass | V1 changes only `ShapeField.resolveTriangleType`; this audit keeps V1 source unchanged. |

No formal-English claim is weaker than the public issue intent for the reported mechanism. No claim depends on hidden tests, upstream patches, or evaluator results.
