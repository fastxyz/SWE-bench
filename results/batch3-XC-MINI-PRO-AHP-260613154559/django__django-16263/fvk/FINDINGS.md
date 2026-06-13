# FINDINGS.md — django-16263

Plain-language findings from formalizing the V1 fix, each as
`input → observed vs expected`. Findings are non-blocking advice; the code
edits applied in V2 are noted inline. "V1" = the fix as left after the first
task; "V2" = after this FVK pass.

---

## F1 — **CRITICAL BUG (V1): non-aggregate multi-valued annotations are stripped, breaking `count() == len(qs)`**

- **input:** `Book.objects.annotate(x=F('authors__name')).count()` where
  `authors` is a multi-valued (M2M) relation; say 6 books with 9 total
  book–author pairs.
- **observed (V1):** `x` is a non-aggregate annotation, unreferenced, so
  `_strip_unused_annotations` deletes it and `_unref_annotation_joins` drops the
  `authors` join → `SELECT COUNT(*) FROM book` → **6**.
- **expected:** `len(list(Book.objects.annotate(x=F('authors__name'))))` is
  **9** (the M2M join multiplies rows; each book appears once per author). By
  Django's contract `count() == len(qs)`, `count()` must be **9**. Base commit
  Django returns 9.
- **why:** the row count of an *ungrouped* query depends on the joins in the
  FROM clause. A non-aggregate annotation over a to-many relation adds a
  multiplying join and does **not** force a GROUP BY (`_annotate` sets
  `group_by=True` only for `contains_aggregate` annotations). Removing that
  join changes the matched-row count. Aggregates are immune because the GROUP
  BY they force collapses the multiplication.
- **classification:** code bug (non-universal postcondition — STRIP-PRESERVES-COUNT
  fails for this input class).
- **fix (V2):** added `Query._annotation_is_strippable(annotation)` —
  `contains_aggregate OR introduces no join beyond the base table` — and gate
  `unused` on it. Multi-valued non-aggregate annotations are now **kept**
  (identical to base-commit behaviour); the count stays 9.
- **discharges:** PROOF_OBLIGATIONS PO1.

## F2 — **GAP (V1): `distinct(*fields)` references not tracked**

- **input:** `Book.objects.annotate(c=Lower('name')).distinct('c').count()`
  (annotation used only as a DISTINCT ON target).
- **observed (V1):** `_get_referenced_annotation_aliases` inspected WHERE,
  GROUP BY, ORDER BY, and other annotations — **not** `self.distinct_fields`.
  `c` is base-only and unreferenced ⇒ stripped. The subsequent DISTINCT-ON
  path (`get_aggregation` keeps ordering when `distinct_fields` is set) would
  reference a column no longer selected → wrong result or error.
- **expected:** an annotation named in `distinct(*fields)` must be kept.
- **note:** Django generally requires `distinct(*fields)` to match `order_by`,
  which *would* be caught by the ORDER BY scan; but relying on that coupling is
  fragile, and a clean spec must list DISTINCT ON as a reference site.
- **classification:** missing reference site (under-approximation of REF-COMPLETE).
- **fix (V2):** added `self.distinct_fields` to the string-reference scan in
  `_get_referenced_annotation_aliases`.
- **discharges:** PO2.

## F3 — **ASSUMPTION (documented): identity-based reference detection relies on the single-clone invariant**

- **input:** `Book.objects.annotate(c=Count('ch')).filter(c__gt=2).count()`.
- **behaviour:** filters embed the *resolved annotation object itself* into the
  WHERE node (not a named `Ref`), so `_gen_annotation_refs` detects it via
  `id(expr) in annotations_by_id`. This is correct **only if** the object in
  `self.where` is identical (by `id`) to the one in `self.annotations[c]`.
- **why it holds here:** `get_count`/`exists` do exactly one `clone()`;
  `Query.clone` shallow-copies `annotations` (same objects) and
  `WhereNode.clone` does **not** clone leaf `Lookup`s (they have no `.clone`),
  so the lookup's `lhs`/`rhs` stays the same object as `annotations[c]`.
  `F('c')`/`Ref('c')` references are caught by name independently.
- **classification:** soundness-relevant assumption, currently satisfied.
- **action:** documented (no code change). Re-verify if `get_count`/`exists`
  ever start from a relabeled/multiply-cloned query. PROOF.md §6 lists it as a
  trusted-base item.

## F4 — **LIMITATION: raw-SQL `extra()` reference sites not scanned**

- **input:** `Book.objects.annotate(c=…).extra(order_by=['c']).count()`.
- **observed:** `extra_select`/`extra(where=…)`/`extra_order_by` are raw SQL
  strings, not ORM expressions; `_get_referenced_annotation_aliases` does not
  scan them.
- **expected vs risk:** standard SQL cannot reference a SELECT alias in WHERE,
  and `extra_order_by` referencing an annotation *alias* by string is
  pathological and unsupported. Risk is negligible, but the spec cannot
  *prove* completeness over raw SQL.
- **classification:** escalation boundary (raw-SQL opacity), not a code bug.
- **action:** documented; no change. Conservative direction (a missed
  reference would wrongly strip) — accepted as out-of-contract for raw extra().

## F5 — **CONSERVATISM (intentional): to-one-join non-aggregate annotations are kept, not stripped**

- **input:** `Book.objects.annotate(x=F('publisher__name')).count()`
  (`publisher` is a to-one FK; no multiplication).
- **observed (V2):** `x` has a column on the `publisher` join (non-base) and is
  not an aggregate ⇒ `_annotation_is_strippable` returns `False` ⇒ kept ⇒
  computed inside a subquery.
- **expected:** the *value* is correct (to-one join doesn't multiply →
  `count() == len(qs) ==` number of books); only the SQL is less minimal than
  it could be.
- **classification:** missed optimisation, **not** a correctness gap. Detecting
  to-one vs to-many precisely needs join-cardinality inspection; deferred in
  favour of a provably safe rule.
- **action:** documented in ITERATION_GUIDANCE as a possible refinement.

## F6 — **POSITIVE: aggregate stripping is safe (GROUP BY collapse)**

- `Book.objects.annotate(Count('chapters')).count()` → strip `chapters__count`
  (aggregate) + drop its join → `SELECT COUNT(*) FROM book` → 6, equal to
  `Book.objects.count()` and to `len(qs)` (the GROUP BY-by-pk that the base
  commit used also yields one row per book). This is the headline ticket case;
  it is **correct** and remains so in V2. Discharges PO1 (aggregate branch).

## F7 — **POSITIVE: dropping GROUP BY in `exists()` is row-existence-neutral**

- `Book.objects.annotate(Count('chapters')).exists()` → V1/V2 drop the GROUP BY
  (no referenced aggregate) → `SELECT 1 FROM book LEFT JOIN chapter LIMIT 1`.
  Existence is invariant under grouping (grouping a non-empty set is non-empty)
  and under LEFT joins (they never delete base rows). Result unchanged.
  Discharges PO5. The HAVING case
  (`…filter(c__gt=2).exists()`) keeps the GROUP BY because `c` is a *referenced
  aggregate* — preserving correctness of the HAVING.

## F8 — **POSITIVE/SCOPE: combinator (UNION/…) queries are skipped**

- `_strip_unused_annotations` returns early when `self.combinator` is set, and
  `exists()` keeps the original GROUP BY expansion under a combinator. SELECT
  column alignment across combined queries makes pruning unsafe; skipping is
  conservative and matches base-commit behaviour. Discharges PO4 (no-regression
  on combinators).

## F9 — **SCOPE (positive): stripping is confined to `count()`, not `aggregate()`**

- The stripping runs inside `get_count` (deleting annotations from the cloned
  query *before* `get_aggregation`), so `QuerySet.aggregate()` is byte-for-byte
  unchanged. This protects the many `annotate(...).aggregate(...)` tests, whose
  results can legitimately depend on existing-annotation joins (the classic
  multi-join multiplication). Confirmed by re-reading `get_aggregation` (reverted
  to its base-commit body). Discharges PO4 (aggregate-path no-regression).

---

## Proof-derived findings from `/verify`

- **PD1 (PO1):** Constructing STRIP-PRESERVES-COUNT forced a case split on
  `is_agg` vs `joins`. The non-aggregate-with-joins branch is exactly where the
  postcondition fails in V1 → drove the F1 fix. The clean predicate
  `_annotation_is_strippable` makes the split explicit; the spec is now writable
  cleanly (no awkward case left open).
- **PD2 (PO2):** Enumerating reference sites for REF-COMPLETE flushed out the
  missing `distinct_fields` (F2). No other ORM-object reference site remained
  once WHERE/HAVING(=where)/GROUP BY/ORDER BY/DISTINCT/transitive/seed were
  listed.
- **PD3 (PO3):** The UNREF-EXACT obligation only needs to hold on the inputs
  `_unref_annotation_joins` is now called with — **aggregates with joins** and
  **base-only** annotations (V2 gate). For base-only it is a no-op; for
  aggregates the per-column parent-chain walk exactly matches `setup_joins`'
  one-ref-per-column-path accounting. The risky general case (arbitrary
  expression owning joins not surfaced by `_gen_cols`, e.g. via a nested
  `Subquery`) is now unreachable for stripping because such annotations are
  non-aggregate-with-(no-outer-)cols → base-only → no joins to unref.
- **PD4 (PO6):** The closure loop's `seen`-guard gives the decreasing measure
  `|annotations| − |seen|`; termination is immediate. No infinite-loop risk.
- **PD5 (escalation):** The adequacy of the mini-ORM row-count model versus real
  SQL `GROUP BY`/`LEFT JOIN`/`DISTINCT` semantics is an `[ESCALATION BOUNDARY]`
  (PROOF.md §6) — it is argued, not machine-checked against a full SQL semantics.
