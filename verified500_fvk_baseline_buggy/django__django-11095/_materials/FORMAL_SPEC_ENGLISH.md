# Formal Spec English

Status: constructed, not machine-checked.

## Claim GET-INLINES-DEFAULT

For a `ModelAdmin` object whose `inlines` attribute is `INLINES`, calling the
default `get_inlines(REQUEST, OBJ)` returns exactly `INLINES`.

## Claim GET-INLINE-INSTANCES-HOOK

Calling `get_inline_instances(REQUEST, OBJ)` first dispatches
`get_inlines(REQUEST, OBJ)` on the same `ModelAdmin`. The loop then processes
the returned inline class list, not the raw `inlines` attribute.

## Claim GET-INLINE-INSTANCES-PRESERVE-FILTER

For each inline class selected by `get_inlines(REQUEST, OBJ)`, the existing
instance construction and permission filter is preserved:

- instantiate with `(model, admin_site)`;
- skip when no relevant view/change, add, or delete permission exists;
- set `max_num = 0` when add permission is unavailable;
- append otherwise.

## Claim TO-FIELD-ALLOWED-FRAME

The related-object validation registry used by `to_field_allowed()` remains
based on static `admin.inlines`; it is not affected by the new dynamic hook.

## Claim CHECKS-FRAME

Admin checks remain static and continue to validate `ModelAdmin.inlines`, not a
request/object-dependent `get_inlines()` result.
