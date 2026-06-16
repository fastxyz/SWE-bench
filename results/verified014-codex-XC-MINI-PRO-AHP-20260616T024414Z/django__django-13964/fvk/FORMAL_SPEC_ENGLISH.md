# Formal Spec English

Status: constructed, not machine-checked.

## C1: Empty Local FK Refresh

For every non-`None` related primary-key value `PK`, if save preparation sees a
cached relation object, the object is truthy, the object's target value is
`PK`, and the owner's local relation attname is the empty string value, then
preparation terminates with the local relation attname equal to `PK`, the
relation cache still present, and no `ValueError`.

## C2: Unsaved Related Object Guard

If save preparation sees a cached truthy related object whose primary key is
`None`, then preparation terminates in the modeled `ValueError` outcome and
does not refresh the local relation attname.

## C3: Non-Empty Stale Value Cache Clearing

If save preparation sees a cached truthy related object with a non-`None`
primary key, the owner's local relation attname is not empty, and the related
object's target value differs from that local value, then preparation leaves the
local value unchanged and clears the owner-side relation cache.

## Loop/Frame Obligation

The K claims model one relation-field iteration. The Python loop over
`self._meta.concrete_fields` is interpreted as a finite sequence of independent
iterations. Fields that are not cached relations are skipped and do not affect
the modeled field's post-state.
