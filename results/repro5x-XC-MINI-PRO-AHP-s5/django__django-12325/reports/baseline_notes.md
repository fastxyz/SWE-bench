# Baseline notes — django__django-12325

## Issue summary

For a multi-table-inheritance (MTI) child model that declares **more than one
`OneToOneField` pointing at the same parent**, the choice of which field becomes
the parent link (and therefore the promoted primary key) depended on the
*declaration order* of the fields:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(Document, on_delete=models.CASCADE, parent_link=True, related_name='+')
    origin = models.OneToOneField(Document, related_name='picking', on_delete=models.PROTECT)
```

This raised `django.core.exceptions.ImproperlyConfigured: Add parent_link=True
to appname.Picking.origin.`, while swapping the two field declarations made it
work. The explicit `parent_link=True` marker was being ignored when a later,
unrelated `OneToOneField` to the same parent was declared after it.

## Root cause

`ModelBase.__new__` in `django/db/models/base.py` builds a `parent_links`
mapping of `{parent_model_tuple: OneToOneField}` that later (in
`Options._prepare`, `django/db/models/options.py`) is used to pick the field
that gets promoted to the model's primary key / parent link.

The original collection loop was:

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        parent_links[make_model_tuple(related)] = field
```

`base._meta.local_fields` is ordered by field creation counter, i.e. by
declaration order. The assignment `parent_links[key] = field` **unconditionally
overwrites** any previously recorded link for that parent. So when two
`OneToOneField`s target the same parent, the *last declared* one wins —
regardless of whether it was the one marked `parent_link=True`.

In the failing example the loop first records `document_ptr` (the real parent
link) and then overwrites it with `origin`. `Options._prepare` then promotes
`origin` to be the parent link, finds `origin.remote_field.parent_link` is
`False`, and raises `ImproperlyConfigured: Add parent_link=True to
appname.Picking.origin.` (`django/db/models/options.py` lines ~241–257).

## Fix

File changed: `django/db/models/base.py` (the parent-link collection loop in
`ModelBase.__new__`, around line 203).

The loop now (1) gathers the candidate `OneToOneField`s, (2) sorts them so that
fields declared with `parent_link=True` are considered first, and (3) records a
field only if no link has been recorded for that parent yet (it never overwrites
an existing entry):

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

`sorted(..., reverse=True)` on the boolean `parent_link` puts `True` before
`False`; Python's sort is stable, so declaration order is preserved among fields
with the same `parent_link` value. Combined with the "don't overwrite" guard,
this guarantees that whenever an explicit `parent_link=True` field exists for a
parent it is the one stored in `parent_links`, independent of field order.

Behaviour after the fix, verified by tracing:

- `document_ptr` (parent_link) + `origin` (plain), in *either* order → the
  parent link is `document_ptr`. The bug is fixed and order no longer matters.
- A lone plain `OneToOneField` to the parent (e.g. the issue's
  `some_unrelated_document`, and the existing
  `invalid_models_tests.test_missing_parent_link` `ParkingLot.parent` case) →
  still recorded in `parent_links`, so `Options._prepare` still raises the
  helpful `Add parent_link=True to ...` error. This established behaviour is
  preserved.
- Single `parent_link=True` field, abstract-base parent links
  (`model_inheritance.test_abstract_parent_link`), and the multi-parent
  `model_meta` `Child(FirstParent, SecondParent)` case → unchanged, because the
  new logic only differs from the old when a single class declares multiple
  `OneToOneField`s to the *same* parent.

No other source files needed changes; `Options._prepare`'s error path is
intentionally left intact because it remains the correct response when the only
`OneToOneField` to the parent lacks `parent_link=True`.

## Assumptions and rejected alternatives

- **Rejected: only collect fields where `field.remote_field.parent_link` is
  `True`** (i.e. add `and field.remote_field.parent_link` to the `isinstance`
  check). This is the change Simon Charette's comment hints at, and it does fix
  the reported ordering bug. I rejected it because it changes long-standing,
  tested behaviour: a model whose *only* `OneToOneField` to its parent is not
  marked `parent_link=True` would no longer raise `ImproperlyConfigured: Add
  parent_link=True to ...`. Instead Django would silently auto-create a separate
  `<parent>_ptr` link. That breaks the existing
  `invalid_models_tests.ModelTests.test_missing_parent_link` test
  (`ParkingLot.parent`) and, more broadly, makes the `Add parent_link=True`
  error in `options.py` unreachable (every entry in `parent_links` and every
  auto-created link would then have `parent_link=True`). The chosen sort/guard
  approach keeps that diagnostic working while still fixing the bug, and it
  matches the PR proposed in the public hints.

- **Cross-base precedence ("first wins" vs "last wins").** The new guard means
  the *first* base (in `reversed([new_class] + parents)` iteration order) that
  records a link for a given parent wins, whereas the old code let the last
  writer win. This only matters if an abstract base *and* the child (or two
  abstract bases) both declare a `OneToOneField` to the same concrete parent —
  a pathological combination not present in the test models I inspected
  (`model_inheritance`, `model_inheritance_regress`, `model_meta`,
  `invalid_models_tests`). For the realistic single-class multi-O2O case that
  this issue is about, all candidates live in one base, so the within-base sort
  fully determines the result. I judged this acceptable and consistent with the
  proposed upstream fix.

- **Assumption:** `field.remote_field.parent_link` is the canonical flag for a
  parent link (confirmed by its use in `Options._prepare`), and
  `resolve_relation` / `make_model_tuple` (already imported in `base.py`) are
  the correct helpers to key the mapping by target model. The fix reuses exactly
  these, so no new imports were required.
