# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO-1 | Keyword `None` entries are removed before reverse candidate matching and substitution. | E1, E2, E3, E6; F1 | Discharged by code inspection and `KWARGS-DROP-NONE` / `OPTIONAL-KWARGS` claims. |
| PO-2 | Positional `None` entries are removed before reverse candidate matching and substitution. | E3, E4; F2 | Discharged by code inspection and `ARGS-DROP-NONE` / `OPTIONAL-ARGS` claims. |
| PO-3 | Removing `None` makes the shorter optional URL candidate eligible when the optional capture is absent. | E1, E2, E8; F1, F2 | Discharged by symbolic candidate-shape reasoning. |
| PO-4 | Non-`None` falsey values are preserved, especially empty strings from nonexistent template variables. | E5; F3 | Discharged by the `is not None` predicate and `EMPTY-STRING-PRESERVED` claim. |
| PO-5 | Existing `ValueError` behavior for mixed positional and keyword arguments is preserved. | Existing API behavior; F4 | Discharged by code ordering: the check precedes normalization. |
| PO-6 | Public caller compatibility is preserved. | E6, E7; F4 | Discharged by unchanged signatures and unchanged call protocol. |
| PO-7 | Regex matching, quoting, converters, resolver population, and default checks are not altered except through normalized argument inputs. | Source diff; F5 | Discharged by diff inspection; retained as a frame condition. |

No proof obligation requires a V2 source change beyond V1.

