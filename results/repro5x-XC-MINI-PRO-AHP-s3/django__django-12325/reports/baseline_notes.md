# Baseline notes — django__django-12325

## Issue

Multi-table inheritance (MTI) parent-link/PK setup gets confused when a child model
declares **more than one** `OneToOneField` pointing at the same parent, and the order
of those fields matters:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE,
                                        parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking',
                                  on_delete=models.PROTECT)
```

This raises `ImproperlyConfigured: Add parent_link=True to appname.Picking.origin`,
whereas declaring `origin` *before* `document_ptr` works. Order should not matter when
an explicit `parent_link=True` marker is present.

## Root cause

`django/db/models/base.py`, in `ModelBase.__new__`, collects candidate parent links into
the `parent_links` dict:

```python
parent_links = {}
for base in reversed([new_class] + parents):
    ...
    for field in base._meta.local_fields:
        if isinstance(field, OneToOneField):
            related = resolve_relation(new_class, field.remote_field.model)
            parent_links[make_model_tuple(related)] = field   # <-- blind overwrite
```

The dict is keyed solely by the *related model* (`make_model_tuple(related)`). When two
`OneToOneField`s target the same parent model they collide on the same key, and the
assignment is a blind overwrite, so **the last field in declaration order wins** —
without regard to whether it is the field actually marked `parent_link=True`.

Downstream, `Options._prepare` (`django/db/models/options.py`) promotes the collected
parent link to the primary key and validates it:

```python
field = next(iter(self.parents.values()))
...
if not field.remote_field.parent_link:
    raise ImproperlyConfigured('Add parent_link=True to %s.' % field)
```

So when `origin` (a regular `OneToOneField`) wins the overwrite race, it is wrongly
chosen as the parent link and the validation rightly complains about it.

## Fix

File: `django/db/models/base.py` (the `parent_links` collection loop).

Instead of blindly overwriting, keep track of the field already collected for a given
related model and **never let a regular `OneToOneField` replace one that is explicitly
marked `parent_link=True`**:

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        related_key = make_model_tuple(related)
        existing = parent_links.get(related_key)
        if (existing is not None and
                existing.remote_field.parent_link and
                not field.remote_field.parent_link):
            # A OneToOneField explicitly marked as a parent link takes
            # precedence so that the parent link selection doesn't depend on
            # the order in which fields are declared. Don't let a regular
            # OneToOneField override an already collected parent link to the
            # same model.
            continue
        parent_links[related_key] = field
```

Behavior of the new condition — set `parent_links[related_key] = field` unless we would
be replacing an existing **parent-link** field with a **non-parent-link** field:

- `document_ptr` (parent_link) before `origin` (regular): `document_ptr` collected
  first; `origin` is skipped → `document_ptr` wins. ✔ (previously failed)
- `origin` (regular) before `document_ptr` (parent_link): `origin` collected first, then
  `document_ptr` (a parent link) is allowed to replace it → `document_ptr` wins. ✔
  (unchanged)
- The selection is now independent of declaration order, which is the reported fix.

### Why it is correct in all orderings, including abstract-parent mixes

The explicit condition (rather than "first-wins" or "last-wins") is what makes the result
order-independent. Consider an abstract mixin contributing one of the fields:

- mixin contributes a *regular* O2O, child contributes the *parent link*: the mixin's
  field is collected first, but the child's parent link is allowed to override it.
- mixin contributes the *parent link*, child contributes a *regular* O2O: the parent link
  is collected first and the child's regular field is **not** allowed to override it.

A plain "prefer the parent-link via sorting + first-wins" or "sorting + last-wins" only
handles one of those two directions; the explicit guard handles both while still
preserving the previous last-wins behavior among equally-ranked (non-parent-link) fields.

## What is intentionally preserved

A child whose **only** `OneToOneField` to the parent is *not* marked `parent_link=True`
still raises `ImproperlyConfigured: Add parent_link=True to ...`. That is Django's
documented design and is locked in by `invalid_models_tests.test_models.test_missing_parent_link`
(`ParkingLot.parent`). My change keeps registering such non-parent-link fields in
`parent_links`, so that error path is unchanged. The "simpler case" raised in the issue
hints (a lone unrelated O2O to the parent) therefore still errors by design — only the
multiple-field ordering ambiguity is fixed.

## Files changed

- `django/db/models/base.py` — `ModelBase.__new__` parent-link collection loop: replaced
  the blind `parent_links[...] = field` overwrite with a guard that prevents a regular
  `OneToOneField` from displacing an already-collected `parent_link=True` field for the
  same related model.

No other files needed changes: `Options.get_ancestor_link` and the related-field
descriptor logic both read from `self.parents`, which is derived from this dict, so once
the correct field is selected here everything downstream is correct.

## Assumptions and rejected alternatives

- **`field.remote_field.parent_link` is always a bool on a `OneToOneField`.** Verified:
  `OneToOneRel`/`ForeignObjectRel` always set `parent_link` (default `False`) in
  `django/db/models/fields/reverse_related.py`, and only `OneToOneField`s are ever stored
  in `parent_links`.

- **Rejected: only collect `parent_link=True` fields.** This would make `parent_links`
  empty for the lone non-parent-link case, causing an auto-created `*_ptr` to be added and
  silently turning `test_missing_parent_link` from an error into success — a behavior
  change and a test regression. Rejected.

- **Rejected: the community-suggested "sort by `parent_link` reverse + only set if key
  absent" (first-wins) patch from the issue hints.** It fixes the reported single-class
  ordering case but, for an abstract base that contributes a regular O2O while the child
  declares the actual `parent_link`, the abstract field is registered first and the real
  parent link is then skipped — selecting the wrong field. The explicit guard avoids that.

- **Rejected: changing `Options._prepare`'s `next(iter(self.parents.values()))` or the
  `ImproperlyConfigured` check.** The defect is upstream in field *selection*, not in
  validation; fixing selection keeps the change minimal and leaves the (correct) error
  message intact for genuinely misconfigured models.
