# Baseline notes — django__django-12325

## Issue

In multi-table inheritance (MTI), the parent-link detection gets "confused by
multiple OneToOne references". With a child model that declares an explicit
parent link **and** another `OneToOneField` to the same parent, the result
depends on declaration order:

```python
class Document(models.Model):
    pass

class Picking(Document):
    document_ptr = models.OneToOneField(
        Document, on_delete=models.CASCADE, parent_link=True, related_name='+')
    origin = models.OneToOneField(
        Document, related_name='picking', on_delete=models.PROTECT)
```

raises `django.core.exceptions.ImproperlyConfigured: Add parent_link=True to
appname.Picking.origin.`, while declaring `origin` *before* `document_ptr`
works. Order should not matter when an explicit `parent_link=True` marker is
present.

## Root cause

`ModelBase.__new__` in `django/db/models/base.py` collects candidate parent
links into a dict keyed by the related model:

```python
parent_links = {}
for base in reversed([new_class] + parents):
    ...
    for field in base._meta.local_fields:
        if isinstance(field, OneToOneField):
            related = resolve_relation(new_class, field.remote_field.model)
            parent_links[make_model_tuple(related)] = field   # <-- last one wins
```

Because the dict is keyed only by the *target model*, every `OneToOneField`
pointing at the same parent overwrites the previous entry. The selection is
therefore purely positional ("the last declared field wins") and completely
ignores the `parent_link=True` flag.

In the failing example both `document_ptr` and `origin` point at `Document`, so
`parent_links[Document]` ends up holding `origin` (declared last). Later,
`Options._prepare()` (`django/db/models/options.py`) promotes that field to the
primary key / parent link:

```python
field = next(iter(self.parents.values()))   # == origin
field.primary_key = True
self.setup_pk(field)
if not field.remote_field.parent_link:       # origin has parent_link=False
    raise ImproperlyConfigured('Add parent_link=True to %s.' % field)
```

Since `origin` is not a parent link, the `ImproperlyConfigured` error is raised.
Reversing the declaration order happens to leave `document_ptr` as the last
write, which is why the "working" ordering works by accident.

## Fix

File changed: `django/db/models/base.py` (the `parent_links` collection loop
inside `ModelBase.__new__`).

The fix keeps collecting **all** `OneToOneField` instances but makes the
selection deterministic: a field explicitly marked `parent_link=True` is the
real link to the parent and must never be overwritten by an ordinary
`OneToOneField` pointing at the same model.

```python
for field in base._meta.local_fields:
    if isinstance(field, OneToOneField):
        related = resolve_relation(new_class, field.remote_field.model)
        related_key = make_model_tuple(related)
        existing = parent_links.get(related_key)
        # When several OneToOneFields point to the same model, the one
        # flagged as the parent link (parent_link=True) must win regardless
        # of declaration order. Once found, don't let another field override it.
        if existing is not None and existing.remote_field.parent_link:
            continue
        parent_links[related_key] = field
```

Behavior of the new rule for a given target model:

* no entry yet -> store the field;
* the stored entry is a `parent_link` -> keep it (skip the new field);
* the stored entry is a regular `OneToOneField` -> overwrite it (so a later
  `parent_link`, or simply the last regular field, still wins as before).

This makes field order irrelevant whenever an explicit `parent_link=True` is
present, while preserving every other existing behavior.

## Why this is the right scope

* **Multiple OneToOneFields, one marked `parent_link=True` (the reported bug):**
  `document_ptr` is now always chosen, in either declaration order. Fixed.

* **A single, unmarked `OneToOneField` to the parent** (e.g.
  `tests/invalid_models_tests/test_models.py::test_missing_parent_link`, and the
  "simpler case" mentioned in the issue's comments): the field is still
  collected and still selected as the parent-link candidate, so
  `Options._prepare()` still raises `Add parent_link=True to ...`. This is the
  documented, intentional behavior: implicit promotion of a `OneToOneField` to a
  parent link was deprecated and required to be explicit (see
  `docs/releases/1.10.txt` and `docs/internals/deprecation.txt`, scheduled for
  removal in 2.0). The fix deliberately does **not** change this — it only
  disambiguates when *several* fields compete.

* **`parent_link` declared on an abstract base** (e.g.
  `tests/model_inheritance/tests.py::test_abstract_parent_link`): the abstract
  parent link is stored first and is not overwritten, so it keeps winning.
  Preserved.

* **Multiple plain `OneToOneField`s to the same model** (none marked): the last
  one still wins, exactly as before (the new guard only protects an existing
  *parent_link* entry).

## Files changed

* `django/db/models/base.py` — only the `parent_links` collection loop in
  `ModelBase.__new__`. No change to `options.py`; the
  `ImproperlyConfigured('Add parent_link=True ...')` check there is still
  correct and reachable (it must fire for a lone unmarked `OneToOneField`).

No other location duplicates this logic — migration state rendering reuses the
same `ModelBase` metaclass, so the fix is centralized.

## Assumptions and alternatives considered

* **Assumption:** a lone unmarked `OneToOneField` to the parent must keep
  raising `Add parent_link=True`. Backed by the existing test
  `test_missing_parent_link` and the explicit deprecation that implicit parent
  links must be marked. The issue comment proposing that this case should
  silently work was treated as out of scope (it contradicts that documented
  behavior).

* **Rejected — filter to `parent_link` fields only**
  (`if isinstance(field, OneToOneField) and field.remote_field.parent_link:`).
  This was Simon Charette's musing in the ticket and is the smallest diff, but
  it makes a lone unmarked `OneToOneField` no longer be selected, so Django would
  silently auto-create the `*_ptr` column and the `Add parent_link=True` error in
  `options.py` would become dead code. That breaks `test_missing_parent_link` and
  changes long-standing, documented behavior beyond the scope of this bug.

* **Rejected — the community PR from the ticket** (sort fields with
  `parent_link` first and use "first write wins", `if related_key not in
  parent_links`). It fixes the reported (single-class) case but, combined with
  the `reversed([new_class] + parents)` iteration, it changes cross-base
  semantics to "first wins". That introduces a regression: a `parent_link`
  declared on a child can be shadowed by an ordinary `OneToOneField` to the same
  model inherited from an abstract base processed earlier. The chosen guard
  ("a stored parent_link is never overwritten; otherwise last write wins") fixes
  the bug without that regression and preserves the previous non-parent-link
  ordering.

* **Rejected — within-base sort only** (sort each base's fields so a
  `parent_link` is processed last, keeping the existing "last write wins"
  assignment). This fixes the reported case with zero cross-base change, but it
  leaves an existing asymmetry: a `parent_link` on an abstract base could be
  overwritten by an ordinary `OneToOneField` declared on the child. The chosen
  guard handles both within-base and cross-base correctly with comparable
  minimality.
