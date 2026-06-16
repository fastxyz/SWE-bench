# Public Evidence Ledger

See `fvk/SPEC.md` for the full ledger table. Critical entries:

- I1: the issue expects zero queries for `user.profile.user.kind`.
- I2: the issue states the inner queryset loaded `kind`.
- I3: the issue identifies the wrong inheritance of deferred fields from the
  outer user instance.
- I4: the public hint says origin-object assignment should remain the default
  but nested prefetches should be able to override it.
- I5: the issue names the ForeignKey reverse relation variant.
- I6: source comments require descriptor prefetch paths to manage relation
  caches manually.

