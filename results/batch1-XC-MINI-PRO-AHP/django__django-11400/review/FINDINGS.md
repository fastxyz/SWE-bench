# Code review findings — django__django-11400 (V1 fix audit)

Scope of V1 (3 files):
- `django/contrib/admin/filters.py` — added `RelatedFieldListFilter.field_admin_ordering()`
  helper; `field_choices()` delegates to it; `RelatedOnlyFieldListFilter.field_choices()`
  now passes `ordering=` through to `get_choices()`.
- `django/db/models/fields/__init__.py` — `Field.get_choices()` applies
  `.order_by(*ordering)` only when `ordering` is non-empty.
- `django/db/models/fields/reverse_related.py` — `ForeignObjectRel.get_choices()` likewise.

Verdict: **V1 is correct and complete; it stands unchanged.** Detailed findings below.

---

## F1 — Core mechanism: empty `ordering` correctly falls back to `Meta.ordering` (CORRECT)
The root cause was that `get_choices()` always did `.order_by(*ordering)`; with `ordering=()`
this expands to a bare `.order_by()`, which `Query.add_ordering()` translates into
`default_ordering = False` (`django/db/models/sql/query.py:1881`), *suppressing*
`Meta.ordering`. V1 guards the call with `if ordering:`, so for an empty ordering no
`order_by()` is issued at all.

Verified the fallback is then honored end-to-end:
- A fresh `Query` initializes `default_ordering = True` (`sql/query.py:168`).
- `QuerySet.complex_filter()` (`query.py:916`) chains via `add_q`/`_filter_or_exclude` and
  never touches `default_ordering`, so it stays `True`.
- `SQLCompiler.get_order_by()` (`sql/compiler.py:263-273`): with `extra_order_by` empty,
  `default_ordering=True`, and `order_by` empty, control reaches
  `elif self.query.get_meta().ordering:` → the related model's `Meta.ordering` is used.
This is exactly the behavior the issue requests. CONFIRMED.

## F2 — Issue part 1 (`RelatedFieldListFilter` ignoring `Meta.ordering`) is fixed (CORRECT)
With no related `ModelAdmin`, or one whose `get_ordering()` returns `()` (its default —
`return self.ordering or ()`, `admin/options.py:338`), `field_admin_ordering()` returns `()`,
so `get_choices(ordering=())` now defers to `Meta.ordering` (per F1). Previously the choices
were emitted in arbitrary database order.

## F3 — Issue part 2 (`RelatedOnlyFieldListFilter` not ordering at all) is fixed (CORRECT)
The override previously called `field.get_choices(include_blank=False,
limit_choices_to={'pk__in': pk_qs})` with no `ordering`, so choices were never ordered even
when the related `ModelAdmin` defined an ordering. V1 computes `ordering` via the shared
`field_admin_ordering()` helper and forwards it. Combined with F1, it now respects both the
admin ordering and (when that is empty) `Meta.ordering`.

## F4 — Ordering precedence is correct: admin ordering overrides `Meta.ordering` (CORRECT)
When `ordering` is non-empty, `.order_by(*ordering)` runs; `add_ordering()` populates
`query.order_by`, and the compiler's `elif self.query.order_by:` branch (compiler.py:267)
wins over the `Meta.ordering` branch. So the effective precedence is:
related `ModelAdmin.get_ordering()` (if non-empty) → related model `Meta.ordering` → none.
This matches the issue's intent ("fall back to" `Meta.ordering`).

## F5 — No regression on the `formfield`/choice-field code path (CORRECT)
The edited `order_by` block is only reachable when `self.choices is None` (it sits after the
early `return` at `fields/__init__.py:814-820`). The other in-tree callers of
`Field.get_choices()` — `Field.formfield()` (`fields/__init__.py:875`) and
`ModelAdmin.formfield_for_choice_field()` (`admin/options.py:200`) — only call it for fields
that *declare* `choices`, hitting that early return. So those paths are untouched. The
forward-relation path of `get_choices()` is effectively used only by the admin related
filters; the `forms/*.py` matches for `get_choices` are the unrelated form-field
`_get_choices`/`choices` property, not this method.

## F6 — Existing tests `GetChoicesOrderingTests` remain green (CORRECT)
`tests/model_fields/tests.py:221-252` calls `get_choices(..., ordering=('a',))` and
`ordering=('-a',)` for both the forward field and `field.remote_field`. All use a *non-empty*
`ordering`, so V1's `if ordering:` guard takes the same `.order_by(*ordering)` branch as
before — identical results. The fixture models `Foo`/`Bar` (`tests/model_fields/models.py:23,32`)
declare no `Meta.ordering`, so there is no incidental interaction. No regression.

## F7 — `reverse_related.py` rewrite is correct, incl. manager iterability (CORRECT)
The original iterated `self.related_model._default_manager.order_by(*ordering)` (a QuerySet).
When `ordering` is empty V1 must still iterate a QuerySet, so it uses
`self.related_model._default_manager.all()` (a Manager is not directly iterable). `.all()`
returns the manager's queryset with `default_ordering=True`, giving the `Meta.ordering`
fallback. Parallel in shape to the forward implementation. CONFIRMED correct.

## F8 — `field.remote_field.model` resolves for both forward and reverse relations (CORRECT)
`field_admin_ordering()` reuses the *exact* registry lookup the original `field_choices()`
used (`field.remote_field.model`). For reverse relations, `ForeignObjectRel.remote_field`
returns `self.field` (`reverse_related.py:62-64`), so the attribute access does not raise.
Because the lookup expression is unchanged from V1-pre-fix, the model used to source the
admin ordering is unchanged — the refactor is strictly behavior-preserving for that lookup.

## F9 — Backward compatibility of the public API (CORRECT)
`RelatedFieldListFilter`/`RelatedOnlyFieldListFilter` are public (exported in
`contrib/admin/__init__.py.__all__`). V1 only (a) adds a new method `field_admin_ordering`
(purely additive) and (b) keeps `field_choices(self, field, request, model_admin)`'s
signature intact. Third-party subclasses overriding `field_choices` are unaffected; those
that want the new helper can call it. No breaking change.

## F10 — Empty ordering AND no `Meta.ordering`: no behavioral change (CORRECT)
If the related model defines neither admin ordering nor `Meta.ordering`, the compiler's
final `else: ordering = []` branch yields no `ORDER BY` — the same effective result as the
old `.order_by()`-clears-everything behavior. So models without any ordering are not
regressed; only models *with* `Meta.ordering` change (the intended fix).

## F11 — Bonus: custom default-manager ordering is now preserved (IMPROVEMENT, not a risk)
If the related model's `_default_manager.get_queryset()` applies its own `.order_by(...)`,
the old bare `.order_by()` would have cleared it; V1 (empty-ordering → no `order_by` call)
preserves it. This is strictly more correct and not a regression.

## F12 — Pre-existing limitation, NOT introduced by V1: `RelatedOnly` on reverse relations
`RelatedOnlyFieldListFilter.field_choices()` passes `limit_choices_to=` to
`field.get_choices()`. `ForeignObjectRel.get_choices()` does not accept `limit_choices_to`,
so using this filter on a *reverse* relation would `TypeError`. This predates V1 (the
`limit_choices_to` kwarg was already there); V1 only added `ordering=`, which the reverse
signature *does* accept. Out of scope for this issue; left unchanged.

## F13 — Pre-existing limitation, NOT introduced by V1: cross-relation `Meta.ordering`
If a related model's `Meta.ordering` traverses a to-many relation, the added JOIN could
duplicate rows in the choices (the outer query in both filters has no `.distinct()`). This
is an existing characteristic of ordering-with-joins and was already reachable via a related
`ModelAdmin.ordering` that spans relations; `Meta.ordering` is almost always local fields.
Not introduced by V1 and out of scope; left unchanged.

## F14 — `include_blank` / blank-choice handling unaffected (CORRECT)
Both methods still prepend `(blank_choice if include_blank else [])`; the filters call with
`include_blank=False`. The ordering change only affects the data list, not the blank-choice
logic. No interaction.

## F15 — Docs / release notes intentionally not modified (DECISION)
`get_choices()` is a semi-internal API and is not documented in `docs/ref/models/fields.txt`
(no `get_choices`/`ordering` references found there). Release notes are not part of the
testable behavior and the original task mandates a minimal, targeted change. No docs edited.
