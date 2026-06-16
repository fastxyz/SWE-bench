# Public Evidence Ledger

Status: constructed for audit; no commands were executed.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Use Python type hints for UML generation" | UML type collection must consult type annotations, not only assigned values. | Encoded by PO1, PO2, PO3. |
| E2 | prompt | `def __init__(self, a: str = None): self.a = a` | Direct assignment from annotated parameter `a` to instance attribute `a` must collect `str`. | Encoded by PO1 and claim `PARAM-ANNOTATION-COLLECTED`. |
| E3 | prompt | "Expected behavior... `a : String`" | For a collected builtin string type not represented as a diagram node, the renderer must have a displayable type for the attribute. | Encoded by PO4 and claim `DISPLAY-BUILTIN-TYPE`. |
| E4 | implementation | `ClassDiagram.get_attrs` calls `class_names` over `instance_attrs_type` and `locals_type`. | The repair should feed astroid type nodes into existing maps, not create a separate renderer. | Encoded by PO4 and PO5. |
| E5 | implementation | Original `handle_assignattr_type` and `visit_assignname` used `node.infer()` only. | Value inference must remain part of the collected set. | Encoded by PO2 and PO5. |
| E6 | implementation | `class_names` skips classes already in the diagram and association extraction uses collected type nodes. | User-defined annotated classes should keep existing association behavior. | Encoded by PO4. |
| E7 | prompt | "PEP 484" and comments about type hinting becoming common | The issue points beyond a single spelling, but does not specify output for complex type expressions. | Finding F3 records the unproven boundary. |
