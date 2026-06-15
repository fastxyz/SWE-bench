# FVK Notes

The FVK audit confirms V1 should stand unchanged.

## Decisions

- Kept the V1 source guard as written. This is justified by F-001 and PO-RNONE:
  the reported failing state is exactly `return_annotation is None` with
  `return_ is None`, and V1 returns the value unchanged instead of calling
  `.to(...)`.
- Rejected the broader alternative of skipping conversion whenever `return_ is
  None`. F-002, PO-RUNIT, and PO-ADEQUACY-FRAME show that documented unit return
  annotations must remain conversion requests; broadening the guard would weaken
  that contract without public evidence.
- Did not add support for stringified `"None"` annotations. F-003 records this
  as ambiguous and outside the Python 3.6 reproducer domain, and no proof
  obligation requires it.
- Made no changes to public APIs or signatures. PO-FRAME-API and
  `PUBLIC_COMPATIBILITY_AUDIT.md` found no compatibility update required.

## Artifacts

The FVK package under `fvk/` includes the requested files plus the formal core
required by the FVK method: `mini-quantity-input.k`,
`quantity-input-spec.k`, intent/spec audit files, findings, proof obligations,
proof, and iteration guidance.

No tests, Python code, or K tooling were executed.
