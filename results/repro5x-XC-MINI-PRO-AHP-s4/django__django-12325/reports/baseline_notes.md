# Baseline notes — django__django-12325

## Issue

> pk setup for MTI to parent get confused by multiple OneToOne references.

Given multi-table inheritance (MTI) where a child model declares an explicit
parent link **and** another `OneToOneField` to the same parent model, the model
only works if the explicit `parent_link=True` field is declared *last*:

```python
class Document(models.Model):
    pass

# Fails: ImproperlyConfigured: Add parent_link=True to app.Picking.origin.
class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE,
                                        parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking',
                                  on_delete=models.PROTECT)

# Works (only difference is field order):
class Picking(Document):
    origin = models.OneToOneField(Document, related_name='picking',
                                  on_delete=models.PROTECT)
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE,
                                        parent_link=True, related_name='+')
```

The reporter notes that ordering should not matter: an explicit `parent_link=True`
marker is present and should be honoured regardless of declaration order.

## Root cause

The parent-link mapping is built in `ModelBase.__new__`
(`django/db/models/base.py`). The original code was:

```python
# Locate OneToOneField instances.
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        parent_links[make_model_tuple(related)] = field
```

`parent_links` is keyed by the *related (parent) model*. Every `OneToOneField`
to a given parent overwrites the previous entry for that parent, so the **last**
`OneToOneField` declared for a parent wins — its `parent_link` flag is never
consulted.

`Options._prepare` (`django/db/models/options.py`) later promotes the chosen
parent link to the primary key and validates it:

```python
field = next(iter(self.parents.values()))
...
field.primary_key = True
self.setup_pk(field)
if not field.remote_field.parent_link:
    raise ImproperlyConfigured('Add parent_link=True to %s.' % field)
```

So when the non-`parent_link` `OneToOneField` (e.g. `origin`) happens to be the
last one declared, it is the one stored in `parent_links` / `_meta.parents`, and
`_prepare` raises `Add parent_link=True to ... .origin`. Declaring the
`parent_link=True` field last masks the bug because it then overwrites the
non-link field. This is exactly the order dependency described in the issue
(and the related "model still broken / `document_ptr_id` not populated" runtime
symptom, since the wrong field was being used as the parent link / pk).

## Fix

File: `django/db/models/base.py`, `ModelBase.__new__`, the "Collect the parent
links for multi-table inheritance" block.

The `OneToOneField`s of each base are now sorted so that fields flagged with
`parent_link=True` are processed first, and an entry is written into
`parent_links` only if no entry for that parent exists yet:

```python
# Locate OneToOneField instances.
fields = [
    field for field in base._meta.local_fields
    if isinstance(field, OneToOneField)
]
# Sort the fields so that fields explicitly flagged as parent links
# take precedence over any other OneToOneField pointing at the same
# parent. This makes parent link detection independent of the order
# in which the fields are declared on the child model.
for field in sorted(fields, key=lambda f: f.remote_field.parent_link, reverse=True):
    related = resolve_relation(new_class, field.remote_field.model)
    related_key = make_model_tuple(related)
    if related_key not in parent_links:
        parent_links[related_key] = field
```

`sorted(..., reverse=True)` on the boolean `parent_link` key places
`parent_link=True` fields before `parent_link=False` fields, and Python's stable
sort preserves declaration order among fields with the same flag. Combined with
the `if related_key not in parent_links` guard, the explicit parent link always
wins for a given parent, regardless of where it appears in the class body. Both
field orderings in the issue now resolve to `document_ptr` as the parent link,
with `origin` remaining an ordinary `OneToOneField`.

No other files were changed.

## Behaviour preserved / why this is minimal

* **Single non-`parent_link` `OneToOneField` to the parent** still raises
  `Add parent_link=True to ...` (the long-standing, helpful diagnostic asserted
  by `invalid_models_tests.test_missing_parent_link`). With only one candidate
  field, it is still registered as the parent link and `_prepare` still flags the
  missing `parent_link=True`.
* **Abstract parent links** (`model_inheritance.test_abstract_parent_link`,
  `model_inheritance_regress.ParkingLot4A/4B`) are unaffected: the single
  `parent_link=True` field on the abstract base remains the sole candidate, so
  the same entry is produced as before.
* Concrete parent classes are still skipped by the surrounding loop, so the new
  cross-field precedence only applies among the OneToOneFields of the model being
  constructed (plus abstract bases), exactly where the ambiguity arises.

## Alternatives considered and rejected

1. **Only collect fields with `parent_link=True`** (i.e. add
   `and field.remote_field.parent_link` to the `isinstance` check). This would
   also fix the reported case, *and* it would make a lone non-`parent_link`
   `OneToOneField` to the parent be ignored — Django would silently auto-create a
   `<parent>_ptr` link instead. That changes documented behaviour and breaks
   `test_missing_parent_link` (which deliberately expects the
   `Add parent_link=True` error), so it is too broad. The chosen fix keeps that
   diagnostic intact while removing the order dependency.

2. **Requiring `primary_key=True` on the parent link** (one of the workarounds
   mentioned in the hints). This is a user-side workaround, does not address the
   order sensitivity, and the reporter confirmed the model can still be broken
   even with it. Not a code fix.

3. **Keeping the original "last wins" overwrite but special-casing only when a
   later non-link field would overwrite a link field.** This is just a more
   convoluted way to express "prefer the parent_link field"; the sort-based
   approach is clearer and order-independent.

## Assumptions

* The intended semantics are that an explicit `parent_link=True` field is
  authoritative: when several `OneToOneField`s target the same parent, the one
  marked as the parent link must be selected. The error message and the
  `_prepare` promotion logic both confirm this is the intended single-link model.
* `field.remote_field.parent_link` is a plain boolean (default `False`), which is
  true for `OneToOneField`/`OneToOneRel` (verified in
  `django/db/models/fields/related.py`), so it is safe as a sort key.
