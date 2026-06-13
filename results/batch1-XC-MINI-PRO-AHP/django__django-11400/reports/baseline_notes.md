# Baseline notes — django__django-11400

## Issue

Ordering problem in `admin.RelatedFieldListFilter` and `admin.RelatedOnlyFieldListFilter`:

1. `RelatedFieldListFilter` does not fall back to the ordering defined in the related
   model's `Meta.ordering`. The ordering is only taken from the related model's
   `ModelAdmin` (`get_ordering(request)`); when that admin defines no ordering (or no
   admin is registered for the related model), the list filter choices come out unordered.
2. `RelatedOnlyFieldListFilter` never orders the related choices at all — not even when
   ordering *is* defined on the related model's `ModelAdmin` — because its
   `field_choices()` override called `field.get_choices()` without the `ordering` kwarg.

## Root cause

`Field.get_choices()` (and the analogous `ForeignObjectRel.get_choices()`) built the
related queryset with `....order_by(*ordering)`. When `ordering` is the empty tuple `()`
— which is the default and the value produced by `ModelAdmin.get_ordering()` when no
admin ordering is configured — this expands to a bare `.order_by()` call.

A bare `.order_by()` does **not** mean "no ordering preference / use the model default".
Tracing the QuerySet machinery:

- `QuerySet.order_by()` (`django/db/models/query.py`) calls
  `clear_ordering(force_empty=False)` then `add_ordering()` with no field names.
- `Query.add_ordering()` (`django/db/models/sql/query.py`) has an explicit branch: when
  the `ordering` argument is empty it sets `self.default_ordering = False`.

Setting `default_ordering = False` actively *suppresses* the model's `Meta.ordering`.
So `get_choices(ordering=())` deliberately stripped any default ordering, which is the
opposite of the desired "fall back to `Meta.ordering`" behavior.

Combined with the two filter call sites only ever supplying admin ordering (or nothing),
the related choices ended up with no ordering whenever the admin ordering was empty.

## Changes

### 1. `django/db/models/fields/__init__.py` — `Field.get_choices()`
Only apply `.order_by(*ordering)` when `ordering` is non-empty. When `ordering` is empty,
the queryset is left with `default_ordering = True`, so the related model's
`Meta.ordering` is honored (and a model without `Meta.ordering` still produces no
`ORDER BY`, identical to the previous behavior — no regression).

```python
qs = rel_model._default_manager.complex_filter(limit_choices_to)
if ordering:
    qs = qs.order_by(*ordering)
return (blank_choice if include_blank else []) + [
    (choice_func(x), str(x)) for x in qs
]
```

### 2. `django/db/models/fields/reverse_related.py` — `ForeignObjectRel.get_choices()`
Same guard, for reverse relations (used when the filtered field is a reverse FK/M2M).

```python
qs = self.related_model._default_manager.all()
if ordering:
    qs = qs.order_by(*ordering)
return (blank_choice if include_blank else []) + [
    (x.pk, str(x)) for x in qs
]
```

### 3. `django/contrib/admin/filters.py`
- Extracted the admin-ordering lookup from `RelatedFieldListFilter.field_choices()` into a
  reusable helper `field_admin_ordering(field, request, model_admin)`, which returns the
  related `ModelAdmin`'s ordering or `()` when none is configured. `field_choices()` now
  delegates to it (behavior unchanged for `RelatedFieldListFilter` itself; the actual
  `Meta.ordering` fallback is handled in `get_choices`, see #1/#2).
- `RelatedOnlyFieldListFilter.field_choices()` now computes the ordering via the shared
  helper and passes it through to `field.get_choices(..., ordering=ordering)`, so this
  filter respects both the related `ModelAdmin` ordering and the `Meta.ordering` fallback.

## Resulting precedence (both filters)
1. The related model's `ModelAdmin.get_ordering(request)`, when it yields a non-empty
   ordering.
2. Otherwise the related model's `Meta.ordering`.
3. Otherwise no explicit ordering (unchanged from before).

## Why the fix is contained / no unintended impact
The `order_by(*ordering)` code in `Field.get_choices()` is only reached when
`self.choices is None`, i.e. for relational fields without explicit `choices`. The two
other in-tree callers — `Field.formfield()` and
`ModelAdmin.formfield_for_choice_field()` — only invoke `get_choices()` for fields that
*do* declare `choices`, where the method returns early (before the `order_by` code) and
is therefore unaffected. `ForeignObjectRel.get_choices()` is, per its own docstring, used
only by `RelatedFieldListFilter`. The behavior change is thus limited to the admin related
list filters, which is exactly the reported area.

## Assumptions and rejected alternatives
- **Where to place the `Meta.ordering` fallback.** I put it in `get_choices` (by simply
  not calling `order_by` when there is nothing to order by) rather than in `filters.py`.
  Rejected alternative: have `filters.py` explicitly pass
  `field.remote_field.model._meta.ordering` as the fallback ordering. That would also
  work, but it would have to be duplicated/handled for both forward and reverse relation
  types and is more brittle; letting the QuerySet's existing default-ordering mechanism do
  the job is cleaner and keeps `Field.get_choices()` semantically correct (`ordering=()`
  now genuinely means "no explicit ordering" rather than "force no ordering").
- **Changing `Query.add_ordering` so empty ordering no longer disables default ordering.**
  Rejected: that is shared global query machinery; other code relies on `.order_by()`
  clearing ordering, so changing it risks broad regressions far outside the issue's scope.
- **Only fixing `RelatedOnlyFieldListFilter`.** Rejected: the issue explicitly reports two
  defects (the missing `Meta.ordering` fallback for `RelatedFieldListFilter` and the
  entirely missing ordering for `RelatedOnlyFieldListFilter`); both are addressed.
- I assumed `ModelAdmin.get_ordering()` returns `()` (not `None`) when no ordering is
  configured — confirmed by its implementation (`return self.ordering or ()`), so the
  `if ordering:` guard behaves correctly.
