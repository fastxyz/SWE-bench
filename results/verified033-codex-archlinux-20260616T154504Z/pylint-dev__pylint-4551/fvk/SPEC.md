# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

The audited production change is V1 in
`repo/pylint/pyreverse/inspector.py`. The relevant behavior is pyreverse's type
collection for UML class attributes:

- `visit_assignname` populates `locals_type`.
- `handle_assignattr_type` populates `instance_attrs_type`.
- `ClassDiagram.get_attrs` and `ClassDiagram.extract_relationships` consume
  those maps.

## Intent Ledger

The full public ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The critical entries
are:

- E1: "Use Python type hints for UML generation" means annotations must
  contribute to UML type collection.
- E2: the concrete sample `a: str = None` followed by `self.a = a` must produce
  an attribute type for `a`.
- E3: the expected output has a visible type, "something like: `a : String`".
- E5: existing value inference must be preserved for unannotated assignments.
- E6: existing association behavior must remain possible for user-defined
  classes already in the diagram.

## Formal Model

`mini-pyreverse.k` abstracts the relevant pyreverse path:

- `valueTypes` models the set/list of nodes returned by `node.infer()`.
- `annAssign` models an annotation attached directly to an `AnnAssign`.
- `paramAnn` models the annotation on a directly assigned parameter name.
- `collected` models the map value stored in `locals_type` or
  `instance_attrs_type`.
- `diagramTypes` and `displayed` model the part of `ClassDiagram.class_names`
  relevant to whether a collected type is visible in the attribute label.

The model is intentionally minimal but property-complete for the issue:
passing case `None + ann(str)` maps to displayed `str`; failing legacy case
`None` alone maps to no displayed type.

## Claims

`pyreverse-typehints-spec.k` contains these claims:

- `PARAM-ANNOTATION-COLLECTED`: direct assignment from an annotated parameter
  adds the annotation type to existing inferred values.
- `ANNASSIGN-COLLECTED`: annotated assignments add the annotation type to
  existing inferred values.
- `NO-ANNOTATION-PRESERVES-VALUE-INFERENCE`: with no annotation, collected
  values equal value inference.
- `DISPLAY-BUILTIN-TYPE`: `None` plus parameter annotation `str` displays
  `str`.
- `DISPLAY-SUPPRESSES-DIAGRAM-NODE`: a user class already in the diagram is not
  duplicated in the attribute label, preserving the existing association path.

## Scope Boundary

This spec does not prove full textual rendering for all PEP 484 type
expressions, including `Optional[T]`, `Union`, generics with element types,
string-literal forward references, or type comments. The public issue's
concrete expected behavior is covered by direct inference of annotation nodes.
