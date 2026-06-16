# Spec Audit

Status: adequacy check for constructed claims; not machine-checked.

| Formal claim | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| `FIGURE-SUBFIGURES-STORES-SPACING` | 1, 5 | Pass | Ties spacing to `Figure.subfigures` kwargs. |
| `SUBFIGURE-LAYOUT` | 1, 2, 3 | Pass | Uses average-cell GridSpec-style arithmetic and ratio preservation. |
| `DEFAULT-ADD-SUBFIGURE-ZERO-SPACING` | 4, 5 | Pass | Blocks V1's generic GridSpec leakage. |
| `BBOX-OVERRIDE` | 6 | Pass | Preserves constrained-layout override. |

No claim is candidate-only or legacy-only after the V2 revision. The V1
candidate behavior that read generic GridSpec spacing is recorded as F2 and is
not accepted as intent.
