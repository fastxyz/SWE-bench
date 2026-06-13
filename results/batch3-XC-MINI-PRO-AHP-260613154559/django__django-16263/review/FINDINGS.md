# Code review findings — django__django-16263 (V1 fix)

Scope reviewed: `django/db/models/sql/query.py` changes — `_gen_annotation_refs`,
`_get_referenced_annotation_aliases`, `_unref_annotation_joins`,
`_strip_unused_annotations`, `get_count`, `exists`.

The fundamental contract being audited: **`qs.count()` must equal
`len(list(qs))`** for every queryset, and stripping an annotation must not change
that number. V1 strips unused annotations and (via `_unref_annotation_joins`) the
joins they introduced, then lets `get_aggregation` collapse to
`SELECT COUNT(*) FROM base`. The review found that this is only valid in a subset of
cases.

---

## F1 — [Critical correctness] Multivalued *filter* join + aggregate annotation: count is over-counted
`Book.objects.filter(chapters__title="x").annotate(c=Count("chapters")).count()`

- The aggregate annotation makes `group_by = True`, so evaluating the queryset emits
  `... GROUP BY book.id`, deduplicating the rows multiplied by the multivalued
  `chapters` filter join. Hence `len(qs)` = number of **distinct** matching books, and
  the pre-fix `count()` (subquery + GROUP BY) returns the same.
- V1 finds `c` "unused" (the filter references the *field path* `chapters__title`, not
  the annotation `c`), deletes it, and unrefs **only the annotation's** contribution to
  the `chapters` join. The filter's reference to that join survives, so
  `get_aggregation` takes the else-branch and emits
  `SELECT COUNT(*) FROM book JOIN chapter WHERE chapter.title='x'` — counting
  `(book, chapter)` pairs (duplicates). `count() != len(qs)`. **Regression vs. the
  pre-fix behavior.**

## F2 — [Critical correctness] Non-aggregate annotation with a multivalued join
`Book.objects.annotate(x=F("chapters__title")).count()`

- `F("chapters__title")` is non-aggregate, so `group_by` stays `None`; the queryset
  legitimately returns duplicated rows (one per chapter) and `count()` must reflect
  that multiplication.
- V1 strips `x` and its `chapters` join, yielding `SELECT COUNT(*) FROM book` (no
  multiplication). `count()` now under-counts vs. `len(qs)`. **Regression.**

## F3 — [Critical correctness] Mixed used/unused aggregates cross-multiply
`Book.objects.annotate(used=Count("authors"), unused=Count("chapters")).filter(used__gt=1).count()`

- Django's documented multi-join aggregation behavior: `used` is computed over the
  `authors × chapters` join cross-product, so its value is inflated by the number of
  `chapters`. The pre-fix `count()` counts books whose *inflated* `used` exceeds 1.
- V1 leaves `used` (referenced) but strips `unused` and its `chapters` join. That
  removes the cross-multiplication, changing `used`'s value and thus the `HAVING`
  result and the count. Even when the result is "more correct", it **differs from the
  established behavior** — a silent behavior change.
- Same root issue for `Sum`: `annotate(c=Sum("pages"), d=Count("chapters")).filter(c__gt=100).count()`.

## F4 — [Correctness] Stale `group_by=True` after stripping the only aggregate
`Book.objects.annotate(c=F("name"), d=Count("chapters")).filter(c="x").count()`

- If V1 deleted the aggregate `d` while keeping the non-aggregate `c`, `group_by` stays
  `True` but `c` is now the only selected expression; the count subquery would
  `GROUP BY name`, collapsing distinct books that share a name. Wrong count. (V1 happens
  to keep `d` here because `c` is referenced, but the hazard is real for any partial
  strip that removes all aggregates while keeping a non-aggregate annotation.)

## F5 — [Confirmed correct] `_unref_annotation_joins`
The refcount surgery is sound: each field reference produces exactly one `Col` whose
post-`trim_joins` parent-chain equals the joins that reference left reffed once;
walking each `Col`'s chain to (excluding) the base table un-refs precisely the
annotation's contribution. Shared joins keep other clauses' refs. Subqueries are not
descended into (`Query.get_source_expressions()` returns `[]`), so a `Subquery`/`Exists`
annotation contributes no outer `Col`s and no spurious un-reffing. The base table is
intentionally never un-reffed. **No change needed.**

## F6 — [Confirmed correct] `exists()` GROUP BY drop
Existence is invariant under grouping (`GROUP BY` of a non-empty set yields ≥1 group),
so dropping a `group_by=True` that exists only because of an unused aggregate never
changes the boolean. The `HAVING` case is preserved: an aggregate referenced by the
WHERE clause is detected (`contains_aggregate` over the referenced set) and the
GROUP BY is kept. Multivalued joins are irrelevant for `exists()`. **No change needed.**

## F7 — [Confirmed correct, by design] Scope = `get_count` only
Stripping lives in `get_count`, not the shared `get_aggregation`, so user `aggregate()`
calls (whose results legitimately depend on join multiplication — see F3) are untouched.
**Keep.**

## F8 — [Confirmed correct] Reference detection & cache handling
`_gen_annotation_refs`/`_get_referenced_annotation_aliases` detect references via `Ref`,
`F`, direct object identity (how filters embed annotations), and the transitive closure;
GROUP BY / ORDER BY string refs are handled. Seeding the referenced set with the source
expressions of *unselected* (`alias()`) annotations prevents dangling references. The
`annotation_select` cache is cleared via `set_annotation_mask`; the unsafe early-return
paths don't mutate `self.annotations`, so no stale cache. **No change needed.**

## F9 — [Bug, found during deeper review] Aliased annotations share one object → double un-ref
`Book.objects.annotate(a=Count("chapters"), b=F("a")).count()`

- `resolve_ref` returns the *same* annotation object for `b=F("a")` as for `a`
  (query.py: `return annotation`). The `chapters` join was reffed only once, but V1's
  per-alias `_unref_annotation_joins` loop would walk that shared object twice (for both
  `a` and `b`), driving the join's refcount negative and corrupting bookkeeping.
- Fix: de-duplicate the annotations to un-ref by object identity before walking their
  joins.

---

## Root cause of F1–F4
V1 assumed "an annotation not referenced by filters/ordering/grouping/other annotations
does not affect the result". That is false when the annotation participates in row
multiplication/deduplication: an aggregate annotation's implicit `GROUP BY`
deduplicates rows that a *surviving* multivalued join multiplies (F1), a non-aggregate
multivalued-join annotation multiplies rows itself (F2), and unused annotations can
cross-multiply *kept* aggregates (F3) or leave a stale `GROUP BY` (F4).

## Resolution (implemented in V2)
Make `_strip_unused_annotations` strip **only when it provably preserves the row count**:

1. Strip only when **every** selected (non-excluded) annotation is unused — i.e. no
   selected annotation is referenced (`strippable & referenced` is empty). This
   addresses F3 and F4 (never remove an annotation while a *kept* annotation could depend
   on its join multiplication or on the grouping). Mixed used/unused queries are left
   exactly as before (correct, if not maximally optimized).
2. De-duplicate the annotations by object identity before un-reffing their joins (F9).
3. Before committing, tentatively un-ref the joins and verify the matched-row count is
   unchanged, using `_reffed_join_aliases()` and `_reffed_multivalued_aliases()`
   (conservative: a join is "multivalued" unless it is definitively `many_to_one` or
   `one_to_one`):
   - `group_by is True`: safe only if **no multivalued join remains** (so dropping the
     implicit GROUP BY — which exists solely for the aggregate's LEFT-joined relation —
     can't expose duplicates). Addresses F1. The aggregate's join is necessarily a LEFT
     join (aggregates include rows with zero related objects), so removing it never
     filters base rows.
   - `group_by` is a tuple (from `values()`): always safe — the subquery preserves the
     grouping and annotation joins are LEFT (non-filtering).
   - no GROUP BY: safe only if **no join was removed at all** (`_reffed_join_aliases()`
     unchanged). This is intentionally stricter than "no multivalued join removed":
     without a GROUP BY there is nothing to fall back on, so we don't rely on the LEFT
     assumption for non-aggregate annotation joins. The common no-GROUP-BY case (e.g.
     `Concat` over local fields) has no joins and is still optimized. Addresses F2.
   If unsafe, `reset_refcounts()` restores the snapshot and the query is left unchanged
   (falling back to the correct pre-fix subquery behavior).

The conservative multivalued classification never labels a truly multiplying join as
single-valued, so V2 can only ever be *over*-conservative (keep a subquery), never
produce a wrong count.
