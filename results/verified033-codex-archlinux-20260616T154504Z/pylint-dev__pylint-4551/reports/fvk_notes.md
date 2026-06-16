# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision Summary

V1 stands unchanged. The FVK artifacts construct a proof for the reported
direct-annotation path at the level of pyreverse's type-collection abstraction
and identify no source-code change required for this pass.

## Trace To Findings And Obligations

- Kept the V1 parameter-annotation propagation because Finding F1 identifies
  the root defect and PO1 states the required repair: direct assignment from an
  annotated parameter must add the annotation-inferred type to
  `instance_attrs_type`.
- Kept the V1 `AnnAssign` support because Finding F2 and PO2 show it is the
  same value-only gap on the explicit annotated-assignment path.
- Kept existing value inference unchanged because PO5 requires unannotated
  assignments to continue using the previous inference result.
- Kept the existing renderer and association path unchanged because PO4 covers
  the issue's visible builtin type and PO6 covers suppression/association
  behavior for user classes already in the diagram.
- Made no public API changes because Finding F4 and
  `PUBLIC_COMPATIBILITY_AUDIT.md` show the V1 helpers are private and the
  existing `handle_assignattr_type(node, parent)` signature and map shape remain
  intact.
- Did not implement a complex PEP 484 type-expression renderer because Finding
  F3 and PO7 classify that as an explicit unproven scope boundary rather than a
  requirement of the concrete issue example.

## Artifacts Produced

- Required user-facing FVK artifacts:
  `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`,
  `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.
- Formal/adequacy artifacts required by the FVK docs:
  `fvk/mini-pyreverse.k`, `fvk/pyreverse-typehints-spec.k`,
  `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
