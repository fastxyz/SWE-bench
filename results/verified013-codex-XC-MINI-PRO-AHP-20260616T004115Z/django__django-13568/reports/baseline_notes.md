# Baseline Notes

## Root cause

`django.contrib.auth.checks.check_user_model()` only checked
`cls._meta.get_field(cls.USERNAME_FIELD).unique` when deciding whether the
`USERNAME_FIELD` was unique. A model-level, non-partial `UniqueConstraint` on
that same field guarantees the same uniqueness but leaves the field's `unique`
attribute false, so the auth system check incorrectly emitted `auth.E003` (or
`auth.W004` with custom authentication backends).

## Changed files

`repo/django/contrib/auth/checks.py`

The uniqueness check now also accepts a one-field constraint from
`cls._meta.total_unique_constraints` whose `fields` tuple is exactly the
configured `USERNAME_FIELD`. Django's `Options.total_unique_constraints`
already filters `Meta.constraints` to non-partial `UniqueConstraint` instances,
which matches the issue's requirement for total unique constraints.

## Assumptions and alternatives considered

I treated only single-field `UniqueConstraint(fields=[USERNAME_FIELD])`
constraints as satisfying the auth requirement. A composite constraint such as
`UniqueConstraint(fields=["username", "tenant"])` contains the username field
but does not make usernames globally unique, so accepting any constraint that
merely includes `USERNAME_FIELD` would be too broad.

I did not add separate constraint parsing in the auth app because
`_meta.total_unique_constraints` is already the model metadata API used by
Django for identifying non-partial uniqueness guarantees.
