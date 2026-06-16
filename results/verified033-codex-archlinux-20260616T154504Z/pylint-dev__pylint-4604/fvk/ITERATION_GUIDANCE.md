# FVK Iteration Guidance

Status: V2 source change applied.

## Decision

V1 should not stand unchanged. Findings F2 and F3 showed that V1 fixed the exact
top-level `abc.ABC` repro but left related type-comment import uses uncovered.

V2 updates `repo/pylint/checkers/variables.py` to:

- add `_qualified_names_from_attribute`, which returns dotted prefixes for an
  attribute chain;
- record those dotted prefixes for top-level `astroid.Attribute` annotations;
- continue collecting nested names after the `typing.*` subscript special case
  instead of returning early;
- record dotted prefixes for attributes nested inside subscript annotations.

## Next Manual Checks

When an execution environment is available, run the project tests that cover
`unused-import` and typing imports. Do not remove tests based on this FVK pass
until the K commands in `PROOF.md` have been machine-checked.

Suggested regression coverage:

- `import abc` with `# type: abc.ABC` should not emit W0611.
- `from abc import ABC` with `# type: ABC` should not emit W0611.
- `import abc` and `import typing` with
  `# type: typing.Optional[abc.ABC]` should not emit W0611 for either import.
- `import xml.etree` with `# type: xml.etree.ElementTree` should not emit W0611.
- An unrelated import not referenced by any type annotation should still emit
  W0611.

## Open Boundaries

This pass does not attempt to solve stringized annotations or broader
annotation-resolution semantics. The issue and V2 proof obligations are scoped
to parsed type-comment annotations and the existing `_check_imports` membership
predicate.
