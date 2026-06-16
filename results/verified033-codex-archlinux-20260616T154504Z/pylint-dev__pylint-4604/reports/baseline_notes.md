# Baseline Notes

## Root cause

`unused-import` suppression for type-only imports is driven by
`VariablesChecker._type_annotation_names`. Assignment and `with` statement type
comments already flow through `_store_type_annotation_names`, and function type
comments already call `_store_type_annotation_node` directly.

The helper handled simple names such as `ABC` and subscripted annotations such
as `List[Any]` or `typing.Optional[str]`, but it returned immediately for a
plain attribute annotation such as `abc.ABC`. As a result, `import abc` stayed in
the module's unconsumed import set and was reported as `unused-import`, while
`from abc import ABC` was correctly suppressed because `ABC` is an
`astroid.Name`.

## Files changed

`repo/pylint/checkers/variables.py`

- Updated `_store_type_annotation_node` to recognize `astroid.Attribute`
  annotations and record the `astroid.Name` nodes contained in them.
- This makes `abc.ABC`, `alias.Type`, and similar qualified type-only
  references count as uses of their imported base name for the existing
  `unused-import` suppression logic.

## Assumptions

- Assignment type comments are represented on assign-like nodes as
  `type_annotation`, because the existing checker already calls
  `_store_type_annotation_names` from `leave_assign`, `leave_for`, and
  `leave_with`, and existing functional fixtures rely on that path.
- The intended behavior is to treat qualified type annotations the same way as
  simple-name type annotations for import-usage purposes, without changing the
  normal name-consumption analysis.

## Alternatives considered

- Changing `_check_imports` to inspect annotation strings directly was rejected:
  the checker already centralizes type annotation tracking in
  `_store_type_annotation_node`, and parsing strings there would duplicate
  astroid's parsed annotation representation.
- Marking the import as consumed during regular name visiting was rejected:
  type comments are handled through the type-annotation side channel today, and
  changing the main consumption flow would be broader than necessary.
- Special-casing only the literal `abc.ABC` pattern was rejected because the
  bug is about any imported module or alias used as the base of a qualified type
  annotation.
