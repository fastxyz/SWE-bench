# Spec Audit

Status: constructed for audit; no commands were executed.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| PARAM-ANNOTATION-COLLECTED | Matches E1 and E2: direct assignment from annotated constructor parameter must collect the annotation even when the assigned value is `None`. | Pass |
| ANNASSIGN-COLLECTED | Matches E1 and extends the same annotation-collection rule to explicit annotated assignments without changing rendering. | Pass |
| NO-ANNOTATION-PRESERVES-VALUE-INFERENCE | Matches E5 frame condition: existing unannotated inference behavior is preserved. | Pass |
| DISPLAY-BUILTIN-TYPE | Matches E3 and existing renderer behavior: a collected builtin type not in the diagram is displayable in the attribute label. | Pass |
| DISPLAY-SUPPRESSES-DIAGRAM-NODE | Matches E4 and E6: existing diagram membership filtering is preserved while raw type nodes remain available for association extraction. | Pass |

## Adequacy Result

The formal claims cover the concrete issue path and the important frame
conditions of V1. They do not cover complete PEP 484 text rendering or type
comment support. That limitation is explicit in `INTENT_SPEC.md` and in
Finding F3, so it does not silently justify a broader claim than the public
evidence supports.
