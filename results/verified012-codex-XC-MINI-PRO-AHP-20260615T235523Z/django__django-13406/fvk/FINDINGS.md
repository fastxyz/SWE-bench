# FVK Findings

Status: constructed, not machine-checked. Findings are from static FVK reasoning only.

## F1 - Resolved: `values().annotate()` query restore no longer returns models

Input: a query from `Toy.objects.values('material').annotate(total_price=Sum('price'))`, pickled/unpickled and assigned to `Toy.objects.all().query`.

Observed before V1: the fresh queryset kept `ModelIterable`, so selected values rows were treated as model rows and could crash as reported in `benchmark/PROBLEM.md:29-45`.

Expected: the fresh queryset uses `ValuesIterable`, yielding dictionaries.

V1 status: resolved. `values()` stores `ValuesIterable` on the underlying query at `repo/django/db/models/query.py:836-840`; `Query.clone()` preserves that marker by `__dict__.copy()` at `repo/django/db/models/sql/query.py:295-296`; the setter restores it at `repo/django/db/models/query.py:212-220`.

Proof obligations: PO1, PO3, PO6.

## F2 - Resolved: `values_list()` variants are not collapsed to plain values dicts

Input: current-version queries from `values_list('field')`, `values_list('field', flat=True)`, and `values_list('field', named=True)`, then restored through `qs.query = query`.

Observed risk in the public hint: restoring only `ValuesIterable` would not respect `ValuesListIterable`, `FlatValuesListIterable`, or `NamedValuesListIterable` (`benchmark/PROBLEM.md:53`).

Expected: each mode restores its exact iterable class.

V1 status: resolved for current-version query pickles. `values_list()` records the selected iterable class on the query at `repo/django/db/models/query.py:866-872`, and the setter restores the recorded class.

Proof obligations: PO2, PO3, PO6.

## F3 - Resolved: selected queries without `values_select` still get a non-model fallback

Input: a selected values query whose SQL-level selected columns are represented through `extra_select_mask` or `annotation_select_mask`, not through a non-empty `values_select`.

Observed risk: the public hint's minimal patch only checked `query.values_select`; that misses annotation-only or extra-only selected values queries.

Expected: any query with explicit selected fields must avoid `ModelIterable` on assignment.

V1 status: resolved. The setter checks `value.has_select_fields` rather than only `value.values_select`, then falls back to `ValuesIterable` and selected names when no exact marker exists.

Proof obligations: PO4.

## F4 - Residual limitation: old or manually-created unmarked `values_list()` queries cannot be exactly reconstructed

Input: a selected query that has no V1 `_iterable_class` marker and was originally a `values_list(flat=True)` or `values_list(named=True)` query.

Observed under V1 fallback: assignment uses `ValuesIterable`, so the result is a dict shape rather than the exact values-list variant.

Expected if exact mode information existed: flat mode would yield scalars, named mode namedtuples, and tuple mode tuples.

Classification: residual limitation, not a code bug for this task. Without a marker, the `Query` state does not encode which values-list variant created it. The public docs do not guarantee cross-version pickle compatibility, and V1 writes the needed marker for current-version values-list producers.

Recommended tests: keep or add tests for current-version `values_list()` query pickles in tuple, flat, and named modes. Do not add a claim that old unmarked values-list query pickles recover exact mode.

Proof obligations: PO4 documents the fallback boundary; PO7 documents why exact recovery is underdetermined without metadata.

## F5 - No additional source edit justified after audit

Input: V1 source as audited against the public intent ledger.

Observed: all in-scope obligations for current-version `values()` and `values_list()` query pickle/reassignment are covered by V1's metadata creation plus setter restoration.

Expected: source should change only if an FVK finding identifies a public-intent mismatch.

V1 status: stands unchanged. The only residual limitation is F4, which cannot be solved for unmarked values-list queries without information the old query does not contain.

Proof obligations: PO1-PO7.

