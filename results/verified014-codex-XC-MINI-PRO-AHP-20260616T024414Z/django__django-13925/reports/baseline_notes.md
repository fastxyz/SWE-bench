# Baseline Notes

## Root cause

`Model._check_default_pk()` raised `models.W042` whenever `cls._meta.pk.auto_created`
was true. That condition also matches the parent-link field that Django creates
for multi-table inheritance and then promotes to the child model's primary key.
Such a parent link is auto-created internally, but it is not the implicit
default `id` field that `DEFAULT_AUTO_FIELD` controls. As a result, child models
that inherit a manually specified primary key from a concrete ancestor were
reported as if they lacked a primary key type.

## Files changed

`repo/django/db/models/base.py`

The warning condition in `Model._check_default_pk()` now also requires
`cls._meta.pk is cls._meta.auto_field`. Django records the implicit default
auto primary key as `_meta.auto_field`, while an inherited parent-link primary
key is not that auto field. This keeps `models.W042` for models with an
implicitly generated `id` field and suppresses it for inherited parent-link
primary keys.

## Assumptions

The issue is about concrete model inheritance where a child model's primary key
is the auto-created parent link to an ancestor that already defines its own
primary key. I assumed the warning should continue to appear for ordinary models
with no declared primary key and no configured `DEFAULT_AUTO_FIELD`.

## Alternatives considered

One alternative was to suppress the warning for any model with concrete parents.
I rejected that because it ties the check to inheritance shape instead of the
actual field being warned about.

Another alternative was to check only whether the primary key is an `AutoField`
subclass. I rejected that because Django already tracks the generated auto
field in `_meta.auto_field`, which is more precise and avoids adding another
type-based special case.
