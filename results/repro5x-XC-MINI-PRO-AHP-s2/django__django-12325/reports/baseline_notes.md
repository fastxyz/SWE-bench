# Baseline notes — django__django-12325

## Issue

> pk setup for MTI to parent get confused by multiple OneToOne references.

With multi-table inheritance (MTI), declaring an explicit `parent_link=True`
`OneToOneField` *plus* another `OneToOneField` to the same parent makes the
result depend on field declaration order:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE, parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking', on_delete=models.PROTECT)
```

raises `ImproperlyConfigured: Add parent_link=True to appname.Picking.origin.`,
while swapping the two field definitions works. Order should not matter because
`parent_link=True` explicitly marks the canonical link.

## Root cause

`ModelBase.__new__` in `django/db/models/base.py` builds a `parent_links` dict
that maps each parent model to the `OneToOneField` that links to it:

```python
parent_links = {}
for base in reversed([new_class] + parents):
    ...
    for field in base._meta.local_fields:
        if isinstance(field, OneToOneField):
            related = resolve_relation(new_class, field.remote_field.model)
            parent_links[make_model_tuple(related)] = field
```

The dict is keyed only by the *target model*. When several `OneToOneField`s on
the same class point at the same parent, they collide on that key and the **last
field processed simply overwrites the previous one** — `parent_link` is never
consulted. So whichever of `document_ptr` / `origin` is declared last wins.

That dict is later consumed in the same method:

```python
base_key = make_model_tuple(base)
if base_key in parent_links:
    field = parent_links[base_key]
```

and the chosen `field` becomes `new_class._meta.parents[base]`. In
`Options._prepare` (`django/db/models/options.py:241-257`) the first parent link
is promoted to the primary key and validated:

```python
if not field.remote_field.parent_link:
    raise ImproperlyConfigured('Add parent_link=True to %s.' % field)
```

When `origin` (which has `parent_link=False`) wins the collision, this check
fails — hence the order-dependent error.

## Fix

File changed: `django/db/models/base.py` (parent-link collection loop only).

Instead of letting the last `OneToOneField` win, collect all `OneToOneField`s of
the base and process them sorted so that `parent_link=True` fields come first,
recording only the first field seen per target model:

```python
fields = [
    field for field in base._meta.local_fields
    if isinstance(field, OneToOneField)
]
for field in sorted(fields, key=lambda f: f.remote_field.parent_link, reverse=True):
    related = resolve_relation(new_class, field.remote_field.model)
    related_key = make_model_tuple(related)
    if related_key not in parent_links:
        parent_links[related_key] = field
```

`field.remote_field.parent_link` is always present (it defaults to `False` in
`ForeignKey.__init__`, stored on the `ForeignObjectRel`), so the sort key is
safe. Because `True` sorts before `False` under `reverse=True` and the first
field per key is kept, the canonical `parent_link=True` field is always selected
regardless of declaration order. Sorting is stable, so among equal `parent_link`
values the original declaration order is preserved.

### Behaviour after the fix

- `document_ptr`/`origin` in either order → `document_ptr` (the `parent_link=True`
  field) is chosen → no error.
- A lone non-`parent_link` `OneToOneField` to the parent (e.g.
  `tests/invalid_models_tests/test_models.py::test_missing_parent_link`,
  `ParkingLot.parent`) is still recorded as the (would-be) parent link, so
  `Options._prepare` still raises `ImproperlyConfigured: Add parent_link=True to
  ...` — preserving that documented/tested contract.
- Standard MTI with no explicit link, or with a single `parent_link=True` link,
  is unaffected (no key collisions, so the `not in` guard always admits the only
  candidate, exactly as before).

## Assumptions

- `field.remote_field.parent_link` exists for every `OneToOneField`. Verified:
  `parent_link=False` default in `django/db/models/fields/related.py` (it is
  passed into the `ForeignObjectRel`, the object stored as `remote_field`), and
  the codebase already reads `self.remote_field.parent_link` unconditionally
  (e.g. `related.py:571`, `897`, `1025`).

## Alternatives considered and rejected

- **Only collect `parent_link=True` fields** (i.e. add
  `and field.remote_field.parent_link` to the `isinstance` guard and drop the
  rest). This fixes the reported case but changes behaviour for a lone
  non-`parent_link` `OneToOneField` to the parent: it would silently *auto-create*
  a `<parent>_ptr` link instead of raising. That contradicts the existing
  `test_missing_parent_link` test (`ParkingLot.parent` must raise
  `ImproperlyConfigured`) and the documented requirement that a link to an MTI
  parent be explicitly marked `parent_link=True`. Rejected to avoid regressing
  that contract. (I briefly applied this variant, then reverted it for this
  reason.)

- **Changing the consumer/validation in `options.py`** instead of the collection
  loop. Rejected: the real defect is the lossy dict construction that discards
  the `parent_link=True` field; fixing it at the source keeps the change minimal
  and leaves the pk-promotion/validation logic intact.
