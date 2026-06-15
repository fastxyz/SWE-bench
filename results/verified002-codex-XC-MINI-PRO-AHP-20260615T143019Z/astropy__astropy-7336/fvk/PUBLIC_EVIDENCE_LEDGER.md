# Public Evidence Ledger

Status: constructed from public evidence; not machine-checked.

| ID | Source | Quoted Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt issue title | "`quantity_input` decorator fails for constructors with type hinted return value -> None" | `-> None` must be accepted on constructors decorated with `quantity_input`. | Encoded in QI-NONE and PO-RNONE. |
| E-002 | prompt summary | "when I add the correct return value for the constructor (`None`) then I get an exception, because `None` has no attribute `to`" | The observed `.to` call on a no-return annotation is the bug, not behavior to preserve. | Encoded in F-001 and QI-OLD-BUG. |
| E-003 | prompt reproducer | `def __init__(self, voltage: u.V) -> None: pass` and `PoC(1.*u.V)` | Argument unit validation and constructor no-return annotation must coexist. | Encoded in QI-NONE; argument validation is framed. |
| E-004 | prompt traceback | `return return_.to(wrapped_signature.return_annotation)` followed by `AttributeError: 'NoneType' object has no attribute 'to'` | The failure is localized to return conversion after the wrapped function returns `None`. | Encoded in QI-OLD-BUG and F-001. |
| E-005 | prompt workaround | "not adding the return type typing hint" avoids the issue but harms static type checking | `-> None` should not be removed by users as a workaround; runtime decorator must accept it. | Encoded in I-RET-NONE and PO-RNONE. |
| E-006 | source docstring | "specify a return value annotation, which will cause the function to always return a `Quantity` in that unit" | Non-`None` unit return annotations must still call `.to(annotation)`. | Encoded in QI-UNIT and PO-RUNIT. |
| E-007 | public in-repo tests | `test_return_annotation` expects `-> u.deg` to convert the result unit | Preserve existing unit-return conversion behavior. | Encoded in QI-UNIT and PO-FRAME. |
| E-008 | source code | V1 checks `return_annotation is not inspect.Signature.empty and return_annotation is not None` before `.to(...)` | Implementation fact used to prove the branch split; not an independent intent source. | Checked by proof obligations. |

SUSPECT legacy behavior: the traceback's old `None.to(...)` behavior is public
evidence of the defect, not an expected behavior.
