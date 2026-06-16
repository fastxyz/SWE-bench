# FVK Notes

## Decision

V1 stands unchanged. No additional source edit is justified by the FVK audit.

## Trace To Findings And Obligations

- `repo/sphinx/domains/python.py`

  Kept the V1 change that calls `_parse_annotation(typ, self.env)` inside
  `PyProperty.handle_signature()` and appends `nodes.Text(': ')` plus the parsed
  annotation nodes. This is justified by F-001 and discharges PO-001 and PO-002:
  property `:type:` annotations must produce Python cross-reference-capable
  nodes, not plain text.

- `repo/sphinx/ext/autodoc/__init__.py`

  Left unchanged. F-002 and PO-004 show that `PropertyDocumenter` already emits
  `:type:` from a property getter's return annotation, so changing the autodoc
  producer would be unrelated to the observed consumer-side defect.

- Public API and directive shape

  Left unchanged. F-003 and PO-005 show the method signature, directive option
  schema, return tuple, and directive registration are preserved by V1. The only
  changed behavior is the internal node representation of an existing `:type:`
  annotation.

- Untyped properties

  Left unchanged. PO-003 requires that properties without a `:type:` option do
  not receive a type suffix from the property type-handling fragment. V1 keeps
  the `if typ:` guard, so this frame condition is preserved.

## Proof Status

The proof is constructed but not machine-checked, per F-004 and the task's
restriction against running K tooling. The emitted commands are recorded in
`fvk/PROOF.md`; they were not executed.

## Files Added

Added the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added the support artifacts required by the FVK methodology:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-domain.k`
- `fvk/python-property-spec.k`
