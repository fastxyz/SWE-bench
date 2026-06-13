# PROOF.md — constructed correctness proof for django__django-11400 (V1)

**Status: constructed, NOT machine-checked.** The FVK MVP builds the proof and emits
the `kompile`/`kprove` commands; it does not run the toolchain. A `#Top` from `kprove`
would upgrade this from *constructed* to *machine-verified*. The **Findings**
(`FINDINGS.md`) and the source-verified trusted-base obligations do **not** depend on
that step.

Semantics: `mini_orm.k`. Claims: `mini_orm-spec.k`. Reachability/Circularity background:
`fvk_materials/knowledge/reachability-and-circularities.md`.

There is **no loop circularity**: every patched method is straight-line and the result
comprehension is a pure order-preserving map (`SPEC.md` note L1). So each proof is a
finite chain of **Axiom** (unfold one `[function]` rule = one symbolic-execution step)
+ **Consequence** (a boolean case-split on `isTruthy`), composed by **Transitivity**.
I write `→` for one rewrite step.

---

## 1. (GC-META) — the core of the fix: empty ordering ⇒ `Meta.ordering`  [PO2]

Goal: `choicesOrdering(META, .Ord) ⇒ META`.

```
choicesOrdering(META, .Ord)
  →  effOrdering(getChoicesFwd(META, .Ord))          // rule: choicesOrdering
  →  effOrdering(complexFilter(defaultManager(META))) // rule: getChoicesFwd(_, .Ord)   [if-FALSE: order_by skipped]
  →  effOrdering(complexFilter(qs(.Ord, true, META))) // rule: defaultManager  (default_ordering = TRUE)
  →  effOrdering(qs(.Ord, true, META))                // rule: complexFilter   (ordering state preserved)
  →  META                                             // rule: effOrdering br4  (qs(.Ord, true, META) ⇒ META)
```

Every step is a single Axiom application; no side condition beyond matching. The
decisive step is the second: because `ordering` is empty the `if ordering:` guard is
False, so `.order_by` is **never** called, leaving `default_ordering = true`. The final
step is compiler branch 4. ∎ (constructed)

## 2. (BUG-OLD) — the pre-fix code violates (GC-META)  [PO7]

Goal: `choicesOrderingOLD(META, .Ord) ⇒ .Ord`.

```
choicesOrderingOLD(META, .Ord)
  →  effOrdering(getChoicesFwdOLD(META, .Ord))
  →  effOrdering(orderByQ(complexFilter(defaultManager(META)), .Ord)) // UNCONDITIONAL order_by(*())
  →  effOrdering(orderByQ(qs(.Ord, true, META), .Ord))
  →  effOrdering(qs(.Ord, false, META))               // rule: orderByQ(_, .Ord)  ⇒ default_ordering := FALSE
  →  .Ord                                              // rule: effOrdering br2  (qs(.Ord, false, _) ⇒ .Ord)
```

Result `.Ord ≠ META`: the old code emits **no** ordering, dropping `Meta.ordering`.
This is exactly Finding F1 / the reported regression, and it is the **only** difference
from §1 — a single rule, `orderByQ(_, .Ord) ⇒ qs(.Ord, false, META)`, fires because the
unconditional `.order_by(*())` flips `default_ordering`. The guard `if ordering:`
removes that step. So the one-line fix is **load-bearing and sufficient**. ∎ (constructed)

## 3. (GC-ORD) — non-empty ordering is honored  [PO1]

Goal: `isTruthy(ORD) ⊢ choicesOrdering(META, ORD) ⇒ ORD`. Assume `isTruthy(ORD)` (path
condition).

```
choicesOrdering(META, ORD)
  →  effOrdering(getChoicesFwd(META, ORD))
  →  effOrdering(orderByQ(complexFilter(defaultManager(META)), ORD)) // getChoicesFwd(truthy)  [if-TRUE]
  →  effOrdering(orderByQ(qs(.Ord, true, META), ORD))
  →  effOrdering(qs(ORD, true, META))                 // orderByQ(_, ORD) with isTruthy(ORD)  ⇒ order_by := ORD
  →  ORD                                              // effOrdering br3 (qs(ORD, true, _) with isTruthy(ORD) ⇒ ORD)
```

The two rules with `requires isTruthy(ORD)` fire under the path condition (Consequence
discharges the side condition trivially from the assumption). ∎ (constructed)

## 4. (GC-REV-ORD / GC-REV-META) — reverse relations  [PO3]

Identical to §1/§3 with `allQ` in place of `complexFilter`. Since
`allQ(qs(OB,DO,META)) ⇒ qs(OB,DO,META)` preserves the same state `complexFilter` does
(both are the identity on `(order_by, default_ordering)`), the two derivations are
step-for-step the same and reach `META` (empty `ORD`) and `ORD` (non-empty). ∎ (constructed)

## 5. (FC-ADMIN / FC-META-NOADMIN / FC-META-EMPTYADMIN) — the filter layer  [PO4, PO5, PO6]

`fieldChoicesOrdering(HASADM, AO, META) → choicesOrdering(META, fieldAdminOrdering(HASADM, AO))`.

- **FC-ADMIN** (`HASADM = true`, `isTruthy(AO)`):
  `fieldAdminOrdering(true, AO) → AO`, then by **(GC-ORD)** §3 with `ORD := AO` ⇒ `AO`. ∎
- **FC-META-NOADMIN** (`HASADM = false`):
  `fieldAdminOrdering(false, _) → .Ord`, then by **(GC-META)** §1 ⇒ `META`. ∎
- **FC-META-EMPTYADMIN** (`HASADM = true`, `AO = .Ord`):
  `fieldAdminOrdering(true, .Ord) → .Ord`, then by **(GC-META)** §1 ⇒ `META`. ∎

`RelatedOnlyFieldListFilter.field_choices` (M4) reduces to the same
`fieldChoicesOrdering` because after the fix it computes
`ordering = self.field_admin_ordering(...)` and threads it into
`field.get_choices(..., ordering=ordering)` — the only difference from
`RelatedFieldListFilter` is the `limit_choices_to={'pk__in': pk_qs}` argument, which is
invisible to the ordering algebra (`complexFilter` is the identity on ordering state,
PO10). Hence PO6 follows from PO4/PO5 on the forward-relation domain D2. ∎ (constructed)

## 6. Trusted-base obligations (PO8–PO12) — discharged by source citation

These are *not* discharged by symbolic execution; they assert that `mini_orm.k` mirrors
Django. Each is checked by reading the cited lines (done during this audit):

- **PO8** `order_by` = `clear_ordering(force_empty=False)` then `add_ordering`; empty args
  ⇒ `default_ordering = False` — `query.py:1073-1080`, `1858-1881`, `1883-1891`. ✔
- **PO9** compiler ladder (`extra_order_by` → `not default_ordering`→order_by →
  order_by → `Meta.ordering` → none) — `compiler.py:262-273`. ✔
- **PO10** `complex_filter` (`add_q`/`_filter_or_exclude`, no ordering mutation) —
  `query.py:916-931`; `all()` — `query.py:881`, `manager.py:146`; new-Query
  `default_ordering = True` — `query.py:168`. ✔
- **PO11** `ForeignObjectRel.remote_field = self.field` and
  `related_model = self.field.model` — `reverse_related.py:62-64,78-82`; forward
  `rel_model = self.remote_field.model` — `fields/__init__.py:821`. So the consulted
  model equals the enumerated model (F3). ✔
- **PO12** choices-declared fields return at `if self.choices is not None:` *before* the
  `order_by` code — `fields/__init__.py:814-820`; the only such callers are
  `formfield` (`:875`) and `formfield_for_choice_field` (`options.py:188-200`). So no
  non-filter path is perturbed (F4). ✔

## 7. Residual risk

- **Partial correctness** (PO15): termination of the comprehension is assumed (finite
  queryset), not proved.
- **Trusted base** (`SPEC.md §4`): the proof transfers to the real code *iff*
  `mini_orm.k` faithfully models the cited internals. The risk is concentrated in PO8/PO9
  — the `order_by`/compiler interaction — which I read line-by-line; the abstraction of
  an ordering tuple to one empty/non-empty bit is sound because that is the only
  distinction either the code or the ladder makes (F6, F8).
- **Constructed, not machine-checked**: run `kompile mini_orm.k --backend haskell` then
  `kprove mini_orm-spec.k` (expect `#Top`) to upgrade.

## 8. Test-redundancy recommendation (Benefit 1) — recommendation only, do NOT auto-delete

I cannot see the (hidden) test suite; this maps the *proved contract* onto the tests
that would exist, conditioned on machine-checking.

**Would be subsumed by the proof (flag as redundant only after `kprove` ⇒ `#Top`):**
- a test asserting `RelatedFieldListFilter` choices follow the related model's
  `Meta.ordering` when the admin defines no ordering → entailed by **(GC-META)/(FC-META-*)**.
- a test asserting `RelatedFieldListFilter` follows the related `ModelAdmin.ordering`
  when set → entailed by **(GC-ORD)/(FC-ADMIN)**.
- the analogous two tests for `RelatedOnlyFieldListFilter` (forward relations) →
  entailed by **(GC-ORD)/(GC-META)** via PO6.

**Keep (not covered by the unit proof):**
- integration/end-to-end admin changelist rendering tests (the proof covers the
  ordering directive, not template wiring or the DB result set — trusted-base item 3).
- any test pinning `RelatedOnlyFieldListFilter` behavior on **reverse** relations
  (out-of-domain D2 / F5).
- tests of `get_choices` on **choices-declared** fields (different code path, F4/PO12).
- termination/performance tests (partial correctness, PO15).

**Estimated CI saving:** negligible (a handful of fast filter unit tests). The dominant
value here is **Benefit 2** (the F1 root-cause / F3 correctness confirmations), not test
removal. Per the Honesty gate: **keep all tests until `kprove` returns `#Top`.**
