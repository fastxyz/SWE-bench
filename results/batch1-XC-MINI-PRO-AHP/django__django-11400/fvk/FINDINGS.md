# FINDINGS.md — django__django-11400

Plain-language findings from formalizing the V1 fix. Each is
`input → observed vs expected`. Findings F1–F2 are the **bugs the fix targets**
(now resolved); F3–F8 are audit results on the fix itself.

The Findings report does **not** depend on machine-checking the proof — these stand
on the formalization and the cited source reads alone.

---

## F1 — [RESOLVED BY FIX, root cause] `order_by(*())` suppresses `Meta.ordering`

**Where:** `Field.get_choices` / `ForeignObjectRel.get_choices` built the queryset with
`....order_by(*ordering)` unconditionally.

**input:** `RelatedFieldListFilter` on a relation whose related model defines
`class Meta: ordering = ['name']`, with **no** ordering on the related `ModelAdmin`
(so `ordering == ()`).
**observed (pre-fix):** `order_by(*())` ≡ a bare `.order_by()`, which
(`query.py:1858-1881`) sets `default_ordering = False`; the compiler ladder
(`compiler.py:262-273`) then takes branch 2 and emits the *empty* explicit order_by →
**choices come out in arbitrary/DB order**, `Meta.ordering` ignored.
**expected:** choices ordered by `Meta.ordering` (`['name']`).

This is the regression reported in the issue (introduced in #29835). Modeled as claim
**(BUG-OLD)** `choicesOrderingOLD(META, ()) = ()`. The fix guards the call with
`if ordering:`, so for empty `ordering` `.order_by` is never called, `default_ordering`
stays `True`, and the ladder reaches branch 4 → `Meta.ordering`. Now claim **(GC-META)**
`choicesOrdering(META, ()) = META`. **Resolved.**

## F2 — [RESOLVED BY FIX] `RelatedOnlyFieldListFilter` never ordered at all

**Where:** `RelatedOnlyFieldListFilter.field_choices` called
`field.get_choices(include_blank=False, limit_choices_to={'pk__in': pk_qs})` with **no**
`ordering=` argument.

**input:** `RelatedOnlyFieldListFilter` on a relation whose related `ModelAdmin` defines
`ordering = ['name']`.
**observed (pre-fix):** `ordering` defaulted to `()` inside `get_choices` → unordered
(and additionally hit F1's `Meta.ordering` suppression). The admin ordering was dropped
on the floor.
**expected:** choices ordered by the admin ordering `['name']` (and by `Meta.ordering`
when the admin defines none).
**Fix:** `field_choices` now computes `ordering = self.field_admin_ordering(...)` and
passes it through. Modeled as **(FC-ADMIN)/(FC-META-*)**. **Resolved.**

## F3 — [AUDIT: no bug — invariant confirmed] the admin consulted matches the model ordered

**Concern raised while specifying:** `field_admin_ordering` looks up the admin for
`field.remote_field.model`, but the model whose objects are *enumerated* is
`self.remote_field.model` (forward) / `self.related_model` (reverse) inside
`get_choices`. If these differed, the fix could order by the wrong model's ordering.

**input:** forward `ForeignKey(Author)` on `Book` **and** the reverse `Book` relation
seen from `Author`.
**observed:** forward — `field.remote_field.model = Author`; `Field.get_choices`
enumerates `rel_model = self.remote_field.model = Author`. Reverse —
`ForeignObjectRel.remote_field = self.field` (`reverse_related.py:62-64`) so
`field.remote_field.model = self.field.model = Book`; `ForeignObjectRel.get_choices`
enumerates `self.related_model = self.field.model = Book`.
**expected = observed in both cases:** the admin/`Meta.ordering` consulted is *exactly*
the model being enumerated. **No bug.** (Domain assumption D1 in `SPEC.md`.)

## F4 — [AUDIT: residual risk, accepted] behavior change for any non-filter caller of `get_choices`

**input:** any caller of `Field.get_choices()` / `ForeignObjectRel.get_choices()` on a
**relational** field (`self.choices is None`) that previously relied on the result being
*unordered*.
**observed (post-fix):** such a caller now receives results ordered by the related
model's `Meta.ordering`.
**expected / assessment:** **In-tree this set is empty.** The only callers that reach
the `order_by` code are the two admin filters; the other callers — `Field.formfield`
(`fields/__init__.py:875`) and `ModelAdmin.formfield_for_choice_field`
(`options.py:200`) — invoke `get_choices` **only on fields with declared `choices`**,
which return at the `if self.choices is not None:` early-exit *before* the `order_by`
code (verified). So no in-tree path changes except the intended ones. A hypothetical
external caller would get `Meta.ordering`, which aligns with the issue's intent and is
the more-correct default. **Accepted, not a defect.** (Discharges PO9.)

## F5 — [AUDIT: pre-existing, out of scope] `RelatedOnlyFieldListFilter` ✗ reverse relations

**input:** `RelatedOnlyFieldListFilter` used on a **reverse** relation, so
`field.get_choices` resolves to `ForeignObjectRel.get_choices`.
**observed:** the call passes `limit_choices_to={'pk__in': pk_qs}`, but
`ForeignObjectRel.get_choices(include_blank, blank_choice, ordering)` has **no**
`limit_choices_to` parameter → `TypeError`.
**assessment:** this is **pre-existing** — the pre-fix code already passed
`limit_choices_to` — and the V1 fix only *adds* `ordering=` (which `ForeignObjectRel`
*does* accept). The fix neither introduces nor worsens it, and the issue does not ask
for it. **Out of scope; left unchanged** to keep the change minimal. Recorded so the
next iteration can decide whether `RelatedOnly` should support reverse relations.

## F6 — [AUDIT: no bug] `if ordering:` is the correct empty-vs-nonempty test

**input:** `ordering ∈ {(), [], ('name',), ['name']}` (the shapes `get_ordering`
returns: `self.ordering or ()`).
**observed:** `if ordering:` is False exactly for `()`/`[]` and True for any non-empty
tuple/list; `order_by(*ordering)` accepts both list and tuple. For non-empty `ordering`
the post-fix behavior is **byte-for-byte** the old behavior (still calls
`order_by(*ordering)`); the *only* behavioral delta is the empty case — precisely the
targeted fix.
**expected = observed.** No off-by-one or truthiness pitfall. **No bug.**

## F7 — [AUDIT: no bug] models with **no** `Meta.ordering` still come out unordered

**input:** related model with `Meta.ordering == []` (the default) and empty admin ordering.
**observed:** `if ordering:` false → no `order_by`; ladder branch 4 tests
`elif self.query.get_meta().ordering:` which is falsy for `[]` → branch 5 → no ordering.
**expected = observed:** the fix does **not** invent an ordering where none is defined;
it only *stops suppressing* one that is. No regression for ordering-less models. Modeled
by `effOrdering(qs(.Ord, true, .Ord)) = .Ord`.

## F8 — [SPEC-DIFFICULTY signal: low] the contract is clean; difficulty was localized

Writing the contract was **easy once the queryset was abstracted to
`qs(order_by, default_ordering, Meta.ordering)`** — the empty-vs-nonempty bit is the
whole story. The one subtlety that took real source-reading (and is itself the bug
signal that explains F1) is that **a bare `.order_by()` is not a no-op**: it *disables*
`default_ordering`. That non-obvious asymmetry between "don't call `order_by`" and "call
`order_by()` with nothing" is exactly the trap the original #29835 code fell into. The
clean spec was *not* hard to write, which is consistent with the fix being correct and
well-scoped.

---

## Proof-derived findings from `/verify`

See `PROOF.md`. Summary: all seven correctness claims discharge by unfolding the
`[function]` rules (straight-line symbolic execution); **(BUG-OLD)** discharges to the
counterexample value `()`, confirming the fix is load-bearing. No VC needed Z3 beyond
boolean case-splits on `isTruthy`. No `[ESCALATION BOUNDARY]` arose. The only residual
risk is the **trusted base** (faithfulness of `mini_orm.k` to the cited Django
internals), enumerated in `SPEC.md §4`.
