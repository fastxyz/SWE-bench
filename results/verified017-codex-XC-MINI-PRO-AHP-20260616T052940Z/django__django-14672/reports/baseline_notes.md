# Baseline Notes

## Root cause

`ForeignObjectRel.__hash__()` hashes the relation's `identity` tuple. The base
`ForeignObjectRel.identity` already normalizes `limit_choices_to` with
`make_hashable()` because that value can contain unhashable containers.

`ManyToManyRel.identity` extended the base identity with `self.through_fields`
directly. `ManyToManyField(through_fields=...)` accepts list-like values, so a
list passed as `through_fields` remained inside the identity tuple. When model
checks compared or stored reverse relation objects, hashing the identity raised
`TypeError: unhashable type: 'list'`.

## Changed files

`repo/django/db/models/fields/reverse_related.py`

Changed `ManyToManyRel.identity` to include
`make_hashable(self.through_fields)` instead of `self.through_fields`. This keeps
the public `through_fields` attribute unchanged for existing indexing/slicing
call sites while ensuring the identity tuple can always be hashed.

## Assumptions and alternatives

I assumed the intended behavior is to preserve list input on
`self.through_fields` and only normalize the identity representation, matching
the existing treatment of `limit_choices_to`.

I considered converting `through_fields` in `ManyToManyRel.__init__`, but that
would change the stored attribute's type and affect code paths that may expect
the original list-like value. Normalizing only in `identity` is the smallest
change that fixes the reported hash failure.

I also considered changing `ForeignObjectRel.__hash__()` to hash
`make_hashable(self.identity)`, but that would broaden behavior for every
relation type and hide future identity fields that should be explicitly made
hashable where they are introduced.
