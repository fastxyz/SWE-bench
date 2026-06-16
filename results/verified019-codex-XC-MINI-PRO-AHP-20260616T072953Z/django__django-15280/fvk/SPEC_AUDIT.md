# Spec Audit

All formal English claims pass the intent audit.

- `PRESERVE-CACHED-RELATION` is entailed by the issue's expected zero-query
  access to `user.profile.user.kind` and by the statement that the inner
  queryset loaded `kind`.
- `SEED-MISSING-RELATION` is entailed by the public hint to keep origin-object
  assignment as the default behavior.
- `COVER-RELATION-FAMILY` is entailed by the one-to-one reproducer and the
  issue's explicit ForeignKey note. The forward many-to-one non-multiple cache
  seeding path is included because it is the same descriptor-side mechanism and
  the same cache-winner rule.

No claim is derived solely from V1 or from legacy behavior.

