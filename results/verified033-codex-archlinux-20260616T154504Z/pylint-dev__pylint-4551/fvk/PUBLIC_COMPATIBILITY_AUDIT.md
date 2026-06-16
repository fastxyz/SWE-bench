# Public Compatibility Audit

Status: constructed for audit; no commands were executed.

## Changed Symbols

`repo/pylint/pyreverse/inspector.py`

- Added private static helpers on `Linker`:
  `_infer_node`, `_annotation_from_annassign`, `_annotation_from_argument`,
  `_infer_assignattr_annotation`.
- Kept existing public/internal method signatures:
  `visit_assignname(self, node)` and
  `handle_assignattr_type(node, parent)`.

## Callers And Overrides

- `visit_classdef` still calls `self.handle_assignattr_type(assignattr, node)`
  with the same arguments.
- Searches in `repo/pylint/pyreverse` and pyreverse unit-test code showed no
  public caller requiring a changed signature.
- No subclass override of `handle_assignattr_type` was found in the audited
  source paths.

## Producer/Consumer Shape

- The producer maps remain `locals_type` and `instance_attrs_type`, each mapping
  names to lists of astroid-inferred nodes.
- `ClassDiagram.get_attrs`, `ClassDiagram.class_names`,
  `ClassDiagram.extract_relationships`, and `DiaDefGenerator.get_associated`
  continue consuming the same node-list shape.

## Verdict

No public compatibility change is required for V1. The added helpers are private
implementation details and the existing map shapes and public method signatures
stand.
