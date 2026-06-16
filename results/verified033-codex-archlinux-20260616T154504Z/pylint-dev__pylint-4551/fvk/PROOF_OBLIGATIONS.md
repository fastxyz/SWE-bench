# Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1 - Direct Parameter Annotation Propagation

For every `AssignAttr` whose assigned value is a direct `Name` and whose
enclosing function has an annotation for that parameter, the collected
`instance_attrs_type[attr]` must include every type node inferred from that
annotation, in addition to value inference.

Trace: E1, E2, F1, claim `PARAM-ANNOTATION-COLLECTED`.

## PO2 - Annotated Assignment Propagation

For every `AssignName` or `AssignAttr` that is the target of an `AnnAssign`,
the collected type map must include every type node inferred from the
annotation, in addition to value inference.

Trace: E1, F2, claims `ANNASSIGN-COLLECTED`.

## PO3 - Best-Effort Inference Failure

If value inference or annotation inference raises astroid inference errors, the
linker must continue best-effort collection rather than failing UML generation.

Trace: frame condition in `INTENT_SPEC.md`, V1 `_infer_node`.

## PO4 - Display Path For Reported Sample

When `instance_attrs_type["a"]` contains `None` plus the builtin `str` type, and
`str` is not already represented as a diagram node, `ClassDiagram.get_attrs`
must have enough collected data to display `a : str`.

Trace: E3, F1, claim `DISPLAY-BUILTIN-TYPE`.

## PO5 - Preserve Existing Value Inference

When there is no relevant annotation, collected types must be exactly the
existing value-inference result.

Trace: E5, claim `NO-ANNOTATION-PRESERVES-VALUE-INFERENCE`.

## PO6 - Preserve Existing Association Behavior

When an annotation resolves to a user class already in the diagram, the raw type
node must remain in the collected map for association extraction, while the
attribute label continues suppressing the duplicate class name.

Trace: E6, claim `DISPLAY-SUPPRESSES-DIAGRAM-NODE`.

## PO7 - Explicit Scope Boundary For Complex Type Expressions

Do not claim proof coverage for textual rendering of complex PEP 484
expressions. If future work requires `Optional[str]`, generics, forward
references, or type comments to render in a specific UML form, add a new spec,
renderer design, and public tests.

Trace: E7, F3.
