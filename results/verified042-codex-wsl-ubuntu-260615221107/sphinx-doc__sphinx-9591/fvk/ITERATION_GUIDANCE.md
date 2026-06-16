# Iteration Guidance

Constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

- F-001 identifies the real defect: property type annotations were appended as
  plain text instead of parsed annotation nodes.
- PO-001 and PO-002 are discharged by the existing V1 source change in
  `PyProperty.handle_signature()`.
- F-002 and PO-004 show that changing `PropertyDocumenter` would be unnecessary
  because it already emits `:type:` for property return annotations.
- F-003 and PO-005 show no compatibility problem from the V1 change.
- F-004 is an honesty-gate limitation only; it does not point to a source-code
  defect or justify a different patch.

## Suggested Future Checks

- In a runnable environment, build a doctree containing a `py:property` with
  `:type: Point` and assert that the property signature contains a pending
  Python cross-reference node for `Point`.
- In a K-enabled environment, run the commands recorded in `fvk/PROOF.md`.
- Keep integration tests that exercise Sphinx rendering, because the constructed
  proof covers the local Python-domain consumer path rather than the full HTML
  build pipeline.
