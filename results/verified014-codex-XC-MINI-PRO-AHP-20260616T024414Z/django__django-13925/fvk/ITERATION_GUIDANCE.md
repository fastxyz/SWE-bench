# FVK Iteration Guidance

Status: V1 stands unchanged.

## Code Decision

No additional source edit is recommended. The V1 predicate is the minimal change
that satisfies the intent-derived obligations:

- It fixes the inherited parent-link false positive (F1, F2, PO1).
- It preserves the implicit default auto primary key warning (F3, PO2).
- It preserves explicit-primary-key and override behavior (PO3, PO5).
- It uses an existing metadata discriminator rather than adding an inheritance
  shape special case (PO4).

## Future Test Work

Do not modify tests in this task. For a normal Django patch, add a regression
test where a concrete parent defines the primary key and a child inherits from
that parent. The expected check result for the child is no `models.W042`.

Keep existing tests for implicit default primary keys and explicit primary keys.
Any recommendation to remove tests would require the K commands in `fvk/PROOF.md`
to be run successfully first; this was not done here.

## Residual Risk

The proof is constructed, not machine-checked. The source was inspected but not
executed. The proof also abstracts Django model construction to the metadata
bits relevant to `_check_default_pk()`, so future changes to how `_meta.auto_field`
is produced should be re-audited against PO4.
