# Spec Audit

Status: constructed, not machine-checked.

| Formal-English obligation | Intent match | Reason |
| --- | --- | --- |
| `SELECTOR-DEFAULT-ARRAY` | pass | Intent requires keeping default output behavior unchanged outside pandas-output configuration. |
| `SELECTOR-PANDAS-PRESERVE` | pass | Directly encodes the issue and public hint for selectors such as `SelectKBest`. |
| `SELECTOR-EMPTY-PANDAS` | pass | Empty selected-column output is a boundary case of selector pass-through and must keep existing warning behavior. |
| `SELECTOR-EMPTY-ARRAY` | pass | Existing non-pandas behavior is explicitly preserved. |
| `WRAPPER-FRAME` | pass | Existing `set_output` API controls final pandas wrapping; the spec does not invent a new public option. |
| `INVALID-CONFIG-ORDER` | pass | Public compatibility requires avoiding unnecessary behavior changes. This obligation came from FVK audit of V1, not from the original issue, and is a conservative compatibility condition. |
| Generic transformer dtype preservation excluded | pass | The public hint rejects global support in the short term and narrows feasible support to selectors. |

## Adequacy Result

The formal claims are not weaker than the public intent for the selector case because they require original-DataFrame selected-column output under pandas configuration. They are not stronger than public intent because they do not require dtype preservation for computed transformers and do not alter default output mode.

No claim depends on hidden tests, upstream patches, benchmark results, or legacy behavior described as buggy.
