# Baseline notes — django__django-12325

## Issue summary

For multi-table inheritance (MTI), declaring an explicit parent-link
`OneToOneField(parent_link=True)` together with *another* `OneToOneField`
pointing to the **same** parent model behaves inconsistently depending on the
order in which the fields are declared:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE, parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking', on_delete=models.PROTECT)
```

raises `ImproperlyConfigured: Add parent_link=True to app.Picking.origin.`,
while swapping the two field declarations works. Order should not matter when an
explicit `parent_link=True` marker is present.

## Root cause

In `django/db/models/base.py`, `ModelBase.__new__` builds the `parent_links`
mapping (parent-model-tuple → the `OneToOneField` that links to it) like this:

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        parent_links[make_model_tuple(related)] = field
```

`base._meta.local_fields` is ordered by field creation order. When two
`OneToOneField`s target the same parent model, the dict assignment
**overwrites** the entry, so the *last-declared* field wins — regardless of
whether it is the one marked `parent_link=True`.

In the failing example the last-declared field is `origin`
(`parent_link=False`), so `new_class._meta.parents[Document] = origin`. Later, in
`django/db/models/options.py` `Options._prepare`, the pk-setup promotes that
parent link to the primary key and checks `field.remote_field.parent_link`;
because `origin` is not a parent link it raises
`Add parent_link=True to app.Picking.origin.` When the fields are declared in the
opposite order, `document_ptr` (the real parent link) happens to win and
everything works. This also explains the secondary symptom reported in the
hints (the model staying broken / `document_ptr_id not populated` even after
adding `primary_key=True`): `parents[Document]` still pointed at the wrong field.

## Fix

File changed: `django/db/models/base.py` (the `parent_links` collection loop in
`ModelBase.__new__`).

Instead of letting declaration order decide the winner, the candidate
`OneToOneField`s are now sorted so that fields with `parent_link=True` are
considered first, and an entry is only recorded if one is not already present
for that target model:

```python
fields = [
    field for field in base._meta.local_fields
    if isinstance(field, OneToOneField)
]
# Fields with parent_link=True take precedence over other OneToOneFields to
# the same parent so that declaration order does not matter when an explicit
# parent link is provided.
for field in sorted(fields, key=lambda f: f.remote_field.parent_link, reverse=True):
    related = resolve_relation(new_class, field.remote_field.model)
    related_key = make_model_tuple(related)
    if related_key not in parent_links:
        parent_links[related_key] = field
```

`field.remote_field.parent_link` is a boolean (`OneToOneRel.parent_link`,
defaulting to `False`). `reverse=True` orders `True` before `False`; Python's
sort is stable, so ties (same `parent_link` value) keep their original
declaration order. Combined with the `if related_key not in parent_links`
guard, the result is:

- If any `OneToOneField` to a given parent has `parent_link=True`, that field is
  always chosen, regardless of where it is declared.
- Otherwise the first-declared `OneToOneField` to that parent is chosen, which
  preserves the previous behaviour for models that have a single non-parent-link
  `OneToOneField` to the parent.

This makes the two orderings in the issue behave identically (both now work).

## Why this scope / alternatives considered

- **Filtering to only `parent_link=True` fields** (i.e.
  `if isinstance(field, OneToOneField) and field.remote_field.parent_link`):
  rejected. This would stop a *single* non-parent-link `OneToOneField` to the
  parent from being treated as a parent-link candidate, so Django would silently
  auto-create a `<parent>_ptr` field instead of raising
  `Add parent_link=True to ...`. That changes long-standing, intentional
  behaviour covered by `invalid_models_tests.test_missing_parent_link`
  (`ParkingLot.parent = OneToOneField(Place)` must raise). The chosen fix keeps
  that error path intact — a lone non-parent-link OTO is still selected and
  still produces the helpful error.

- **Encoding `related_name` into the dict key** (suggested in the issue
  discussion): rejected as unnecessary. The parent-link mapping is keyed by
  target model on purpose (there is one parent link per parent model); the only
  real problem was choosing the *wrong* field among candidates for the same
  target, which the `parent_link`-first ordering resolves directly.

- The reported "simpler case" (`some_unrelated_document =
  OneToOneField(Document)` with no `parent_link=True` anywhere) still raises
  `Add parent_link=True`. This is the same, intended behaviour as
  `test_missing_parent_link`: with no explicit parent-link marker Django cannot
  know the field is meant to be unrelated, so requiring `parent_link=True`
  remains correct and is left unchanged.

### Assumptions

- The visible test `invalid_models_tests.test_missing_parent_link` reflects
  intended behaviour and must keep passing; the fix is deliberately limited to
  disambiguating *which* OneToOneField becomes the parent link and does not
  remove the missing-parent-link error.
- `field.remote_field.parent_link` is always available for `OneToOneField`
  (verified: `OneToOneRel.__init__` sets `self.parent_link`, default `False`).
- For the practical MTI scenarios only `new_class` itself contributes candidate
  fields (concrete parents are skipped earlier in the same loop), so the
  `if ... not in parent_links` guard does not alter behaviour for the normal
  single-parent case; it only ensures the parent-link field wins among a base's
  own fields.
