# SPEC.md — formal specification of the V1 fix for django__django-11400

*Constructed with the Formal Verification Kit (`/formalize`). Proof artifacts are
**constructed, not machine-checked** — see `PROOF.md` and the Honesty gate.*

## 0. What is being specified

The V1 fix changes four methods so that the admin related-field list filters order
their choices by **the related ModelAdmin's ordering when non-empty, otherwise the
related model's `Meta.ordering`, otherwise unordered**:

| # | Method | File:line | Change |
|---|--------|-----------|--------|
| M1 | `Field.get_choices` | `repo/django/db/models/fields/__init__.py:809-833` | apply `.order_by(*ordering)` only `if ordering` |
| M2 | `ForeignObjectRel.get_choices` | `repo/django/db/models/fields/reverse_related.py:117-130` | same guard, reverse relations |
| M3 | `RelatedFieldListFilter.field_admin_ordering` + `.field_choices` | `repo/django/contrib/admin/filters.py:196-207` | extract admin-ordering helper |
| M4 | `RelatedOnlyFieldListFilter.field_choices` | `repo/django/contrib/admin/filters.py:425-429` | pass `ordering=` through |

The semantic crux is a single Django invariant about querysets, which I read off the
source and modeled in `mini_orm.k`:

> **`get_order_by` ladder** (`repo/django/db/models/sql/compiler.py:262-273`): the
> ORDER BY actually emitted is — `extra_order_by`, else (if `default_ordering` is
> **False**) the explicit `order_by`, else (if `order_by` non-empty) the explicit
> `order_by`, else (if `Meta.ordering` non-empty) **`Meta.ordering`**, else nothing.
>
> **`add_ordering`** (`repo/django/db/models/sql/query.py:1858-1881`): calling
> `.order_by()` with **no** field names sets `default_ordering = False`.

So `qs.order_by(*())` (i.e. a bare `.order_by()`) flips `default_ordering` to False
and leaves the explicit `order_by` empty → the ladder takes branch 2 → **no ordering
at all, suppressing `Meta.ordering`**. Not calling `.order_by` at all leaves
`default_ordering = True` and the empty explicit ordering → branch 4 → **`Meta.ordering`**.

## 1. The mini-X semantics (`mini_orm.k`)

A queryset is abstracted to the only three fields the ladder reads:
`qs(OB, DO, META)` = (explicit `order_by`, `default_ordering` flag, the model's
`Meta.ordering`). An ordering tuple is abstracted to one bit — `.Ord` (the empty
tuple `()`, Python-falsy) vs any non-empty `Ord` (truthy) — because empty-vs-nonempty
is the *only* distinction the fix and the ladder turn on. Each rewrite rule cites the
Django source it mirrors (`mini_orm.k` header + inline comments). The operations
`defaultManager`, `allQ`, `complexFilter`, `orderByQ`, and `effOrdering` reproduce
`_default_manager`, `.all()`, `.complex_filter()`, `.order_by(*)`, and the compiler
ladder respectively.

> **Note L1 — why there is no loop circularity.** Each patched method is straight-line.
> Its only repetition is the result comprehension `[(... , str(x)) for x in qs]`, which
> is a **pure map that preserves queryset iteration order** and adds a fixed prefix
> (`blank_choice` when `include_blank`). It has no counter, no accumulator arithmetic,
> and no off-by-one surface; the entire ordering question is decided *before* iteration
> by `effOrdering(qs)`. So the FVK "loop circularity" degenerates to a structural
> identity and the contracts below are plain reachability rules (no invariant needed).
> `include_blank=False` at both filter call sites, so the prefix is empty anyway.

## 2. Function contracts (the claims in `mini_orm-spec.k`)

Let `META` be the related model's `Meta.ordering`, `ORD` the `ordering=` argument, `AO`
the related ModelAdmin's `get_ordering(request)` result, and `hasAdmin` whether an admin
is registered for the related model.

- **(GC-ORD)** `isTruthy(ORD) ⟹ choicesOrdering(META, ORD) = ORD`
  — `get_choices` with a non-empty ordering enumerates by that ordering.
- **(GC-META)** `choicesOrdering(META, ()) = META`
  — *the fix*: empty ordering falls back to `Meta.ordering`.
- **(GC-REV-ORD/META)** identical contract for the reverse-relation core (M2).
- **(FC-ADMIN)** `hasAdmin ∧ isTruthy(AO) ⟹ fieldChoicesOrdering(true, AO, META) = AO`.
- **(FC-META-NOADMIN)** `fieldChoicesOrdering(false, AO, META) = META`.
- **(FC-META-EMPTYADMIN)** `fieldChoicesOrdering(true, (), META) = META`.
- **(BUG-OLD)** `choicesOrderingOLD(META, ()) = ()` — the pre-fix core, proving the
  regression existed and that **(GC-META) is false for the old code**, so the fix is
  load-bearing (not cosmetic).

### Composed end-to-end contract (intended behavior)

> For both `RelatedFieldListFilter` and `RelatedOnlyFieldListFilter`, the choices are
> enumerated ordered by **`AO`** if an admin is registered and `AO` is non-empty;
> **else by `META`** (`Meta.ordering`); **else unordered**. This holds for forward
> relations (ForeignKey/ManyToMany, via M1) and for reverse relations reachable by
> `RelatedFieldListFilter` (via M2).

## 3. Preconditions / domain

- **D1.** `field.remote_field.model` is the model whose objects are enumerated as
  choices — verified for forward relations (`Field.get_choices` uses
  `self.remote_field.model`) and reverse relations
  (`ForeignObjectRel.get_choices` uses `self.related_model = self.field.model`, and
  `ForeignObjectRel.remote_field = self.field`, so `remote_field.model = field.model`
  = the same model). Hence `field_admin_ordering` consults the admin of *exactly* the
  model being ordered. (See `FINDINGS.md` F3.)
- **D2.** `RelatedOnlyFieldListFilter` is specified only over **forward** relations,
  because it passes `limit_choices_to=`, which `ForeignObjectRel.get_choices` does not
  accept. This is **pre-existing** and unchanged by the fix (`FINDINGS.md` F5).
- **D3.** Partial correctness: the comprehension terminates iff the queryset is finite
  (always true for a DB-backed manager). Termination is not separately proved.

## 4. Trusted base (must hold for the proof to transfer to the real code)

1. The `mini_orm.k` rules faithfully mirror the cited Django sources
   (`query.py`, `compiler.py`, `query.py` QuerySet methods, `manager.py`,
   the two `get_choices`). Each rule names its source; this is the main assumption.
2. The list comprehension preserves queryset order (note L1) — true of Python
   iteration over a queryset.
3. The DB returns rows in the ORDER BY the compiler emits (Django's own contract; the
   fix operates at the directive level, not the DB level).
4. The reachability proof-system metatheory and the (un-run) `kprove`/SMT oracle.

## 5. Run-commands (constructed, not machine-checked)

```sh
kompile mini_orm.k --backend haskell      # compile the fragment semantics
kprove  mini_orm-spec.k                    # discharge the claims; expected: #Top
```
