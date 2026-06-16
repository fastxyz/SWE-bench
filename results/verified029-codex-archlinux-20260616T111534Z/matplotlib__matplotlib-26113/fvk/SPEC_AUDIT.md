# Spec Audit

Status: adequacy comparison, constructed not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| CLAIM-COUNT-EXPLICIT | E2 | pass | Uses `>= M`, matching "at least". |
| CLAIM-C-EXPLICIT | E1, E3, E4 | pass | Removes the strict `> M` behavior that caused count-one bins to disappear. |
| CLAIM-C-DEFAULT | E5 | pass | Keeps omitted `mincnt` in `C` mode as non-empty only. |
| CLAIM-COUNT-DEFAULT | E6 | pass | Keeps all count-only bins when `mincnt` is omitted. |
| CLAIM-LOOP | E2, E4 | pass | Generalizes the selected-bin predicate over all finite count lists. |
| Reducer frame | E5, E7 | pass with precondition | If a selected reducer result is NaN, existing `good_idxs = ~np.isnan(accum)` still hides that bin. This is outside the threshold comparator itself. |
| Explicit `mincnt=0` in `C` mode | E4 plus docstring `int > 0` | ambiguous but non-blocking | The issue demonstrates the case and requests `>=`; docs describe positive `mincnt`. V1 permits inclusive zero for reducers that can handle empty input, but the proof of the documented contract only relies on positive explicit `mincnt`. |
| Public compatibility | E8 | pass | No signature or call-forwarding change. |

Conclusion: the formal claims cover the public issue's required behavior for
explicit positive `mincnt`, plus the documented/default branches needed to avoid
changing omitted-`mincnt` behavior. No spec mismatch blocks keeping V1.
