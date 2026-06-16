# FVK Notes

## Decision

V1 stands unchanged. No additional source edits were made during the FVK pass.

## Trace to Findings and Proof Obligations

- The original bug is captured by `fvk/FINDINGS.md` F1 and discharged by
  `fvk/PROOF_OBLIGATIONS.md` PO1 and PO6. The V1 guard prevents receiver
  registration for concrete no-dimension `ImageField` instances, and skipping
  the receiver is behaviorally equivalent because the old receiver returned
  immediately.
- Dimension-field behavior is preserved per F2, discharged by PO2, PO3, and PO4.
  This is why V1 should not remove the `post_init` hook entirely.
- Abstract-model behavior is preserved per F3 and PO5. This is why the existing
  `not cls._meta.abstract` condition remains part of the guard.
- Assignment-time updates are preserved per F4 and PO7. This is why no changes
  were made to `ImageFileDescriptor.__set__()`.
- Public compatibility is preserved per F5 and PO8. Constructor arguments,
  deconstruction, descriptor behavior, and signal call shape remain unchanged.
- The proof and tests remain unexecuted per F6 and PO9. The artifacts are
  labeled constructed, not machine-checked, and no test removals are proposed as
  completed.
- The formal core is present in `fvk/mini-django-imagefield.k` and
  `fvk/imagefield-post-init-spec.k`; these files support F6/PO9 by providing
  non-executed commands for a future K-enabled environment.

## Alternative Considered

Removing all `post_init` registration was rejected because it would violate F2
and PO2-PO4 for dimension-bearing fields. Adding a helper for
`self.width_field or self.height_field` was also rejected because it would not
change the proof obligations and would be a broader edit than necessary.
