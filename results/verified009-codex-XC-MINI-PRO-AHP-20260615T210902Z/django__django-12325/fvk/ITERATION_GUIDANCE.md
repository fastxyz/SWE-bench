# ITERATION GUIDANCE

## Decision

V1 should not stand unchanged. The FVK audit found that its `related_name is None` branch preserved legacy behavior without public-intent support.

## Code Change Applied

Changed `repo/django/db/models/base.py` from:

```python
if isinstance(field, OneToOneField):
    ...
    if field.remote_field.parent_link:
        ...
    elif field.remote_field.related_name is None:
        ...
```

to:

```python
if isinstance(field, OneToOneField) and field.remote_field.parent_link:
    related = resolve_relation(new_class, field.remote_field.model)
    parent_links[make_model_tuple(related)] = field
```

## Why

This directly discharges PO1, PO2, PO3, and PO4:

- explicit parent links still populate `parent_links`;
- ordinary one-to-one fields can no longer displace explicit parent links;
- ordinary one-to-one fields no longer block the auto-created parent pointer path;
- field order no longer changes the reported behavior.

## Follow-Up Tests To Add In A Normal Test-Authoring Setting

Do not edit tests in this benchmark task. In a normal workflow, add tests for:

- parent link declared before an ordinary one-to-one field to the same parent;
- parent link declared after an ordinary one-to-one field to the same parent;
- ordinary one-to-one field to parent with no explicit parent link;
- explicit parent link inherited from an abstract base still discovered.

## Open Point

Duplicate explicit `parent_link=True` fields to the same parent remain underspecified (F3). Do not change behavior for that case without a separate public requirement.
