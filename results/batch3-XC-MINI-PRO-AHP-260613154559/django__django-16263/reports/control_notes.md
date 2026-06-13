# Control notes — django__django-16263 (V2)

This documents the outcome of the code review (see `review/FINDINGS.md`) and every
change made (or deliberately not made) to the V1 fix, each traced to a numbered finding.

## Summary of the review outcome
V1 correctly produced `SELECT COUNT(*) FROM base` for the headline case
(`Book.objects.annotate(Count("chapters")).count()`), but the review found that its
core assumption — "an unreferenced annotation can be removed freely" — is false whenever
an annotation participates in row multiplication or deduplication. This made V1 return
**wrong counts** in several realistic cases (F1–F4) and corrupt join refcounts in one
(F9). V2 keeps V1's overall structure and confirmed-correct pieces, and replaces the
stripping decision with one that only fires when it provably preserves the matched-row
count.

All edits are confined to `repo/django/db/models/sql/query.py`.

## Changes

### C1 — Only strip when *all* selected (non-excluded) annotations are unused
`_strip_unused_annotations` now returns early unless `strippable & referenced` is empty,
i.e. no kept (referenced) annotation remains.

- Traces to **F3** (mixed used/unused aggregates: removing `unused` un-does the
  cross-join multiplication of a kept aggregate `used`, changing its value / the HAVING
  result / the count) and **F4** (deleting the only aggregate while keeping a
  non-aggregate annotation would leave a stale `group_by=True`, grouping by the wrong
  column).
- Rationale: if any selected annotation is kept, its value or the grouping can depend on
  the joins introduced by the others, so removing the others is not provably safe.
  Leaving such queries untouched reproduces the exact pre-fix behavior (correct).
- This matches the issue's intent: an annotation that influences a kept aggregate is not
  truly "unused", so it is correctly *not* stripped.

### C2 — De-duplicate annotations by object identity before un-reffing joins
The un-ref loop now iterates `{id(ann): ann ...}.values()` instead of one call per alias.

- Traces to **F9**: `annotate(a=Count("x"), b=F("a"))` makes `annotations["a"] is
  annotations["b"]` (confirmed: `resolve_ref` returns the annotation object directly,
  query.py:2112). The shared object's joins were reffed once, so un-reffing per alias
  drove the refcount negative. De-duplicating by `id()` un-refs each underlying object
  exactly once, matching the refs that were added.

### C3 — Verify the matched-row count is unchanged before committing (multivalued-join check)
After tentatively un-reffing the strippable annotations' joins, `_strip_unused_annotations`
decides `safe` by `group_by` kind, then either commits (delete + re-mask) or
`reset_refcounts()` and bails. Two new helpers support this:
`_reffed_join_aliases()` (referenced joins) and `_reffed_multivalued_aliases()`
(referenced joins that are not definitively `many_to_one`/`one_to_one`).

- `group_by is True` → safe iff **no multivalued join remains**. Traces to **F1**: when a
  multivalued filter join survives (e.g.
  `filter(chapters__title="x").annotate(Count("chapters")).count()`), dropping the
  aggregate's implicit GROUP BY would over-count duplicated rows; V2 detects the
  surviving multivalued join and keeps the correct subquery+GROUP BY. The aggregate's own
  join is necessarily a LEFT join (aggregates include zero-related rows), so removing it
  never filters base rows — `SELECT COUNT(*) FROM base [JOIN single-valued ...]` stays
  correct.
- `group_by` is a tuple (from `values()`) → always safe: the subquery preserves the
  grouping, and annotation joins are LEFT (non-filtering). (`set_group_by`/`values()`
  paths such as aggregation_regress tests 1069/1072 keep returning 4 and 6.)
- no GROUP BY → safe iff **no join was removed at all** (`_reffed_join_aliases()`
  unchanged). Traces to **F2**: a non-aggregate annotation over a multivalued relation
  (`annotate(x=F("chapters__title")).count()`) legitimately multiplies rows, so removing
  its join would change the count. This branch is intentionally stricter than "no
  multivalued join removed" so it does not rely on the LEFT-join property of
  non-aggregate annotation joins; the common no-GROUP-BY case (`Concat` over local
  fields) has no joins and is still fully stripped to `SELECT COUNT(*)`.
- The conservative multivalued classification (`not (many_to_one or one_to_one)`, with
  `Field`/`ForeignObjectRel` defaults verified in
  `fields/__init__.py:163` and `fields/reverse_related.py:99-112`) never labels a truly
  multiplying join as single-valued, so V2 can only ever be *over*-conservative (keep a
  subquery), never produce a wrong count.

## Parts of V1 kept unchanged (justified by the review)

- **`_unref_annotation_joins`** — kept (only invoked via the de-duplicated loop now).
  Confirmed correct in **F5**: per-`Col` parent-chain walk exactly un-refs an
  annotation's post-`trim_joins` joins; the base table is never un-reffed; subqueries are
  not descended into.
- **`exists()` GROUP BY drop** — kept unchanged. Confirmed correct in **F6**: existence
  is invariant under grouping and multiplication (so dropping the GROUP BY is always
  safe, no multivalued analysis needed), and the HAVING case is preserved by detecting a
  referenced aggregate.
- **Scope = `get_count` only** (stripping is not done in the shared `get_aggregation`) —
  kept. Confirmed appropriate in **F7**: `aggregate()` results legitimately depend on the
  join multiplication (F3), so leaving `get_aggregation` untouched avoids regressing
  user aggregates.
- **`_gen_annotation_refs` / `_get_referenced_annotation_aliases`** and the unselected-
  annotation seeding — kept. Confirmed correct in **F8** (reference detection covers
  `Ref`, `F`, identity, transitive closure, and string GROUP BY/ORDER BY refs; no stale
  `annotation_select` cache).
- **`get_count`** still calls `obj._strip_unused_annotations({"__count"})` — unchanged.

## Net effect
V2 strips a strict subset of what V1 stripped (so it introduces no new over-stripping),
removes the cases where V1 was wrong (F1–F4, F9), and still delivers the issue's headline
optimization: `Book.objects.annotate(Count("chapters")).count()` compiles to
`SELECT COUNT(*) FROM book` and equals `Book.objects.count()`, while
`filter(<multivalued>).annotate(<aggregate>).count()` keeps the correct deduplicated
subquery.
