# Evidence excerpts — django__django-16263 (FVK arm, batch3-XC-MINI-PRO-AHP-260613154559)

All paths absolute. Line numbers are as read at analysis time (2026-06-14).

---

## E0. Eval verdict (authoritative)

`/home/xc/Projects/fastxyz-SWE-bench/results/batch3-XC-MINI-PRO-AHP-260613154559/django__django-16263/eval/fvk.report.json`

- `resolved: false`
- **FAIL_TO_PASS** (3 distinct test methods — no subtest over-count):
  - success: `test_non_aggregate_annotation_pruned (aggregation.tests.AggregateAnnotationPruningTests)`
  - failure: `test_unreferenced_aggregate_annotation_pruned (...)`, `test_unused_aliased_aggregate_pruned (...)`
- **PASS_TO_PASS** failure (1 regression):
  - `"Subquery annotations must be included in the GROUP BY if they use"` = `test_aggregation_subquery_annotation_multivalued (aggregation.tests.AggregateTestCase)`

Cross-check (raw tracebacks):
`/home/xc/Projects/fastxyz-SWE-bench/logs/run_evaluation/batch3-XC-MINI-PRO-AHP-260613154559.fvk/batch3-XC-MINI-PRO-AHP-260613154559__fvk/django__django-16263/test_output.txt`
```
FAIL: test_unreferenced_aggregate_annotation_pruned ...
    self.assertEqual(sql.count("select"), 2, "Subquery wrapping required")
AssertionError: 1 != 2 : Subquery wrapping required
FAIL: test_unused_aliased_aggregate_pruned ...
    self.assertEqual(sql.count("select"), 1, "No subquery wrapping required")
AssertionError: 2 != 1 : No subquery wrapping required
FAIL: test_aggregation_subquery_annotation_multivalued ...
    self.assertEqual(author_qs.count(), Author.objects.count())
AssertionError: 10 != 9
Ran 103 tests ... FAILED (failures=3)
```
Identical failure set in baseline; control fails only the two F2P (NOT the multivalued P2P).

---

## E1. The two REMAINING-failing tests (gold test patch)

`/home/xc/Projects/fastxyz-SWE-bench/logs/run_evaluation/batch3-XC-MINI-PRO-AHP-260613154559.goldcheck/gold/django__django-16263/eval.sh` (lines 34-58):
```python
    def test_unused_aliased_aggregate_pruned(self):
        with CaptureQueriesContext(connection) as ctx:
            Book.objects.alias(authors_count=Count("authors")).count()
        sql = ctx.captured_queries[0]["sql"].lower()
        self.assertEqual(sql.count("select"), 1, "No subquery wrapping required")   # <- fvk got 2
        self.assertNotIn("authors_count", sql)

    def test_unreferenced_aggregate_annotation_pruned(self):
        with CaptureQueriesContext(connection) as ctx:
            Book.objects.annotate(authors_count=Count("authors")).count()
        sql = ctx.captured_queries[0]["sql"].lower()
        self.assertEqual(sql.count("select"), 2, "Subquery wrapping required")      # <- fvk got 1
        self.assertNotIn("authors_count", sql)
```
The contract these encode: the SQL **shape** matters. An unreferenced *aggregate* annotation on a multi-valued relation (`annotate(Count("authors"))`) must KEEP the subquery wrapper (2 SELECTs) but DROP the alias; an `alias()`-only (unselected) aggregate must collapse to a single flat `SELECT COUNT(*)` (1 SELECT).

---

## E2. ORACLE mechanism (what the correct fix does)

`/home/xc/Projects/fastxyz-SWE-bench/fvk_bench_analysis/django__django-16263/evidence/oracle.patch.diff`
Bug site: `django/db/models/sql/query.py::Query.get_aggregation`. The gold patch does NOT delete annotations; it (a) gates subquery/GROUP-BY on real *aggregation usage*, (b) keeps the subquery and masks the unreferenced annotation out of SELECT, (c) inlines referenced annotations.
```python
        existing_annotations = {
            alias: annotation
            for alias, annotation in self.annotation_select.items()
            if alias not in added_aggregate_names
        }
        has_existing_aggregation = any(
            getattr(annotation, "contains_aggregate", True)
            or getattr(annotation, "contains_over_clause", True)
            for annotation in existing_annotations.values()
        ) or any(self.where.split_having_qualify()[1:])
        ...
            or has_existing_aggregation        # decide subquery by USAGE, not presence
        ...
                # Mask existing annotations that are not referenced by
                # aggregates to be pushed to the outer query.
                annotation_mask = set()
                for name in added_aggregate_names:
                    annotation_mask.add(name)
                    annotation_mask |= inner_query.annotations[name].get_refs()
                inner_query.set_annotation_mask(annotation_mask)   # keep subquery, drop alias
```
Plus new `get_refs()` on `BaseExpression`/`Ref` (`django/db/models/expressions.py`), `WhereNode.get_refs()` (`django/db/models/sql/where.py`), and a `summarize` flag threaded through `query_utils.py`.

Load-bearing keywords present in the ORACLE diff: `has_existing_aggregation`, `set_annotation_mask`, `get_refs`, `contains_over_clause`, `split_having_qualify`, `Ref(...)` inlining.

---

## E3. FVK artifacts CERTIFY the buggy behavior as correct (the inversion)

The fvk arm's mechanism is "delete the unreferenced annotation + unref its joins, so `get_aggregation` collapses to `SELECT COUNT(*) FROM book`" — and the artifacts assert this is the *desired* output.

`/home/xc/Projects/fastxyz-SWE-bench/results/batch3-XC-MINI-PRO-AHP-260613154559/django__django-16263/fvk/SPEC.md:9-13`:
```
`QuerySet.count()` (and `exists()`) should ignore annotations ... so that e.g.
`Book.objects.annotate(Count('chapters')).count()` runs `SELECT COUNT(*) FROM
book` and returns the same value as `Book.objects.count()`.
```
^ This is the EXACT single-SELECT output that `test_unreferenced_aggregate_annotation_pruned` rejects (it requires `sql.count("select") == 2`).

`fvk/FINDINGS.md:100-106` (F6, marked **POSITIVE**):
```
## F6 — **POSITIVE: aggregate stripping is safe (GROUP BY collapse)**
- `Book.objects.annotate(Count('chapters')).count()` → strip `chapters__count`
  (aggregate) + drop its join → `SELECT COUNT(*) FROM book` → 6 ...
  This is the headline ticket case; it is **correct** and remains so in V2.
```

`fvk/SPEC.md:88-97` (STRIPPABLE predicate) — the aggregate→delete rule, soundness "proved":
```
### (STRIPPABLE) `Query._annotation_is_strippable(annotation)` ...
  `is_agg(annotation) ∨ cols(annotation) ⊆ {base, ⊥}`
  - `is_agg`: the GROUP BY it forced ... collapses any multiplication, and after
    stripping all aggregates the else-branch yields `rowcount = B = ` the grouped value.
```
Same `contains_aggregate` discriminator the oracle uses, but inverted remedy: gold says "aggregate ⇒ keep subquery, mask alias"; fvk says "aggregate ⇒ safe to DELETE".

---

## E4. The `alias()` failure is explicitly designed-in "for safety"

`fvk/FINDINGS.md:118-124` (F8) and the patch docstring deliberately KEEP unselected (`alias()`) annotations — the direct cause of `test_unused_aliased_aggregate_pruned` (which wants them pruned to 1 SELECT):

`solution_fvk.patch:123-125`:
```python
        selected = set(self.annotation_select)
        # Annotations excluded from the selection (e.g. through alias()) are
        # kept, so anything they reference must be preserved as well.
```
The strip set iterates only `selected` (`solution_fvk.patch:139-145`), so an `alias()`-only aggregate is never pruned → its GROUP BY/subquery survives → 2 SELECTs.

---

## E5. The only thing measuring the failing assertion is fenced as ESCALATION BOUNDARY

The mini-ORM abstraction (`fvk/SPEC.md:38-69`) models a query's row COUNT as an integer (`rowcount(Q) = B | |distinct G-tuples| | B*Π fanout`). It deliberately drops the number-of-SELECTs / subquery-presence distinction — which is the only thing the failing tests assert via `sql.count("select")`.

`fvk/SPEC.md:34-36`:
```
... mark the adequacy of the abstraction (mini-ORM ↔ real Django SQL row
semantics) as an explicit `[ESCALATION BOUNDARY]` (see `PROOF.md` §6).
```
`fvk/FINDINGS.md:158-160` (PD5):
```
- **PD5 (escalation):** The adequacy of the mini-ORM row-count model versus real
  SQL `GROUP BY`/`LEFT JOIN`/`DISTINCT` semantics is an `[ESCALATION BOUNDARY]`
```
Per kit policy (and the primer §v#2), an escalation boundary on a capability gap is a KIT limitation, NOT a code-bug finding. The actual root cause lives entirely behind it.

---

## E6. V1 (baseline) vs FINAL (fvk): fvk made only 2 orthogonal edits

`diff solution_baseline.patch solution_fvk.patch` (both edit ONLY `django/db/models/sql/query.py`):
1. Added `_annotation_is_strippable(...)` (the F1 guard for multi-valued *non-aggregate* annotations) and gated `unused` on it.
2. Added `self.distinct_fields` to the reference scan (F2).

Neither touches the two failing aggregate cases nor the multivalued P2P regression → FAIL_TO_PASS stayed 1/3, byte-identical to baseline. fvk did NOT change the architecture; it confirmed V1.

---

## E7. Transcript: agent read every gold-patch file, started the gold path, then reverted it

`/home/xc/Projects/fastxyz-SWE-bench/results/batch3-XC-MINI-PRO-AHP-260613154559/django__django-16263/transcripts/fvk.jsonl.gz`
- Read counts: `sql/query.py` ×31 (the `get_aggregation` site), `expressions.py` ×8 (gold `get_refs` site), `query_utils.py` ×1, `sql/where.py` ×2. All gold-patch files were in view.
- Baseline turn: *"Now let me update the `existing_annotations` computation in `get_aggregation` to strip unreferenced annotations"* — briefly edited the gold site.
- Then reverted: *"The shared `get_aggregation` path is too risky for `aggregate()` ... I'll scope the stripping to `count()` only by doing it in `get_count` ... and revert my `get_aggregation` edits."*
- Mistaken (no-exec) bet: *"no existing test asserts subquery/GROUP BY presence in `count()`/`exists()` SQL."* — the hidden F2P assert exactly that; the arm could not run them.
- Whole-transcript keyword scan: `has_existing_aggregation` = 0 hits; `Subquery wrapping`/`count("select")` = 0 hits; `get_refs` = 2 incidental hits (no use of the gold mechanism).
