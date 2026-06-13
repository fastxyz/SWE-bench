# Baseline notes — django__django-12325

## Issue summary

For multi-table inheritance (MTI), when a child model declares an explicit
parent-link `OneToOneField` (`parent_link=True`) **and** another regular
`OneToOneField` that points to the *same* parent model, Django picks the wrong
field as the parent link depending on the order in which the fields are
declared:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE,
                                        parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking',
                                  on_delete=models.PROTECT)
```

raises `ImproperlyConfigured: Add parent_link=True to appname.Picking.origin.`,
while swapping the declaration order of the two fields works. The explicit
`parent_link=True` marker should make declaration order irrelevant.

## Root cause

`ModelBase.__new__` in `django/db/models/base.py` builds a `parent_links` dict
that maps each parent model to the `OneToOneField` to be used as its MTI parent
link:

```python
parent_links = {}
for base in reversed([new_class] + parents):
    ...
    for field in base._meta.local_fields:
        if isinstance(field, OneToOneField):
            related = resolve_relation(new_class, field.remote_field.model)
            parent_links[make_model_tuple(related)] = field   # plain overwrite
```

Because the assignment is an unconditional dict overwrite, when several
`OneToOneField`s reference the same parent the **last one in declaration order**
wins (fields are ordered by `creation_counter`). So:

- `document_ptr` declared first, `origin` second → `parent_links[Document]`
  ends up being `origin` (not a parent link).
- `origin` first, `document_ptr` second → `parent_links[Document]` ends up
  being `document_ptr` (the real parent link).

The chosen field becomes `Picking._meta.parents[Document]`. Later,
`Options._prepare()` (`django/db/models/options.py:241-257`) promotes the first
parent link to the primary key and raises `ImproperlyConfigured` if that field
is not `parent_link=True`. Hence the order-dependent error. The same wrong
selection is also what causes the secondary runtime symptom mentioned in the
ticket (the `*_ptr_id` column not being populated): the wrong field is wired up
as the parent link.

## Fix

File changed: `django/db/models/base.py` (the `parent_links` collection loop).

The overwrite is replaced with a guarded assignment: a field flagged
`parent_link=True` is always preferred for a given parent, regardless of
declaration order, and a plain `OneToOneField` is never allowed to shadow an
already-recorded explicit parent link. When no field is a parent link, the
previous "last field wins" behavior is retained:

```python
existing = parent_links.get(related_key)
if (existing is not None and
        existing.remote_field.parent_link and
        not field.remote_field.parent_link):
    continue
parent_links[related_key] = field
```

With this, both field orderings from the report select `document_ptr` as the
parent link, and the `ImproperlyConfigured` error no longer appears.

`parent_link` is read from `field.remote_field.parent_link`, which is how it is
stored/consumed elsewhere (e.g. `options.py:254` and
`fields/related.py`). No new imports are required (`OneToOneField`,
`resolve_relation`, `make_model_tuple` were already imported).

## Behavior preserved (regression safety)

- `invalid_models_tests.test_models.ModelTest.test_missing_parent_link`: a lone
  `OneToOneField` to the parent **without** `parent_link=True` must still be
  recorded as the (invalid) parent link so that the helpful
  `Add parent_link=True to ...` error is raised. Because non-parent-link fields
  are still stored in `parent_links` (only their precedence relative to a real
  parent link changes), this error is preserved. This is why the fix does *not*
  simply filter the loop to `parent_link=True` fields only — doing so would make
  Django silently auto-create a `*_ptr` field and break that test/contract.
- `model_inheritance.tests.test_abstract_parent_link` and the existing
  `ParkingLot(Place)` model (explicit `parent_link=True` plus an unrelated
  `ForeignKey`) keep selecting the explicit parent link.

## Assumptions and rejected alternatives

- **The "simpler case" in the hints**
  (`some_unrelated_document = OneToOneField(Document, ...)` with no
  `parent_link=True` anywhere) is *expected* to keep raising
  `Add parent_link=True to ...`. This is the documented requirement enforced by
  `test_missing_parent_link`, not a separate bug; the reporter was conflating it
  with the ordering bug. The fix intentionally leaves it raising.

- **Rejected: the contributor's `sorted(..., reverse=True)` + `if key not in
  parent_links` approach from the ticket.** It correctly prefers parent links
  *within a single base*, but combined with the outer `reversed([...])` loop it
  switches cross-base precedence to "first base wins" (abstract mixins
  processed before `new_class`). In the edge case where an abstract base
  declares a plain `OneToOneField` to a parent and the concrete subclass
  declares the real `parent_link=True` field to the same parent, that approach
  would incorrectly pick the abstract base's plain field. The guarded-overwrite
  approach used here preserves the original cross-base "last wins" precedence
  while still always honoring an explicit `parent_link=True`, so it is strictly
  safer.

- **Rejected: filtering to only `parent_link=True` fields.** As noted above,
  this would break `test_missing_parent_link` and the documented requirement to
  explicitly mark the parent link.
