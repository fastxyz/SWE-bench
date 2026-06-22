# django__django-13569

- **Verdict:** A_GENUINE_FIX — baseline's narrowed `order_by` GROUP BY filter silently drops a multivalued correlated `Subquery` from GROUP BY (a regression baseline introduced); fvk restores the upstream/gold behavior of keeping it.
- **Pitch-worthiness (1-5):** 4

## Benchmark Result

- Baseline arm: official SWE-bench evaluation marked the patch as resolved.
- FVK arm: official SWE-bench evaluation marked the patch as resolved.
- Audit category: baseline passed the benchmark but remained concretely buggy.

## The issue
The ticket: `order_by('?')` (random ordering) was wrongly added to a query's GROUP BY, breaking aggregation. The gold fix changes `Random.get_group_by_cols()` so random expressions are excluded from GROUP BY.

## What baseline did
Instead of gold's targeted change, baseline rewrote the `order_by` GROUP BY logic to only keep order-by expressions that are column references or RawSQL — filtering out everything else. This fixes the reported random-ordering case and passes the tests, but it is **over-broad**: a legitimate multivalued correlated `Subquery` used in `order_by()` has `contains_column_references=False` and isn't RawSQL, so baseline's predicate **drops it from GROUP BY**.

## What fvk changed and why
fvk added a `get_external_cols()` branch so that a correlated subquery's external columns are retained in GROUP BY, restoring the behavior that both original Django and gold have. `fvk_FINDINGS.md` F1 identified exactly this regression.

## Concrete demonstration (executed, Django 3.2 repo checkout)
```python
Author.objects.annotate(c=Count('book')).order_by(
    Subquery(Author.objects.filter(pk=OuterRef('pk'),
                                    book__name=OuterRef('book__name')).values('pk')))
```
| variant | subquery in GROUP BY? |
|---|---|
| original Django / **gold** | **kept** ✅ |
| **baseline** | **dropped** ❌ (regression) |
| **fvk** | **kept** ✅ (matches original/gold) |

Consequence of dropping a multivalued subquery from GROUP BY: on databases that enforce full-group-by (PostgreSQL, MySQL `ONLY_FULL_GROUP_BY`) the query raises "must appear in the GROUP BY clause" or, where tolerated, silently returns incorrect grouped rows — the exact class of bug this ticket is about.

## Why the tests missed it
The hidden suite's multivalued-subquery test (`test_aggregation_subquery_annotation_multivalued`) places the subquery in **select/annotate** (the unmodified code path), never in **order_by**. So baseline's narrowed order_by filter is never exercised on a subquery, and baseline passes.

## FVK vs. Human Fix

**Human fix issue:** no.

The human fix addresses random ordering at the source expression. FVK repairs baseline by retaining order-by expressions with external columns. Both preserve the correlated-subquery grouping behavior that baseline accidentally dropped.

Gold only touches `functions/math.py` (`Random.get_group_by_cols`), leaving the order_by GROUP BY loop intact — so original/gold keep the subquery. fvk's added branch reproduces that. **GOLD_MATCH: partial** (different mechanism, same correct outcome; baseline regressed, fvk did not).

## Confidence & caveats
- **High confidence:** verified by executing the query SQL generation on a real Django 3.2 checkout across original/baseline/fvk.
- The full-group-by *error* itself wasn't run against Postgres; it's the well-known consequence of the confirmed GROUP-BY omission.
