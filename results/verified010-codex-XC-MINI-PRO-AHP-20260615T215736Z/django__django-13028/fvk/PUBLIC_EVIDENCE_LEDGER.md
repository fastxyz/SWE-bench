# Public Evidence Ledger

See `fvk/SPEC.md` for the mirrored ledger entries E-01 through E-05.

Summary:

- The issue report states that a queryset raises `NotSupportedError` when the
  RHS has `filterable=False`.
- The reproducer uses a related model instance as lookup RHS.
- The public hint says to check whether the RHS is an expression.
- Django's expression base class exposes `resolve_expression` and the internal
  `filterable` flag.
- Nearby ORM code uses `resolve_expression` as the expression-protocol
  discriminator.
