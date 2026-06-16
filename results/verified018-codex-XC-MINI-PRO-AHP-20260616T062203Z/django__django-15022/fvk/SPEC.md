# FVK Spec

Status: constructed, not machine-checked.

## Target

`repo/django/contrib/admin/options.py`, method
`ModelAdmin.get_search_results(request, queryset, search_term)`.

## Public intent ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The obligations used by this
spec are:

- O1: split search input into terms, preserving quoted phrases as one term.
- O2: construct ORM lookups exactly as before, including prefix shortcuts,
  explicit lookups, `pk`, and default `icontains`.
- O3: build the documented predicate shape: AND over search terms, OR over
  search fields for each term.
- O4: avoid the issue's per-token `qs = qs.filter(...)` pattern.
- O5: submit all term clauses to one ORM `add_q()`/filter operation so related
  joins are reusable within that operation.
- O6: preserve duplicate detection from `lookup_spawns_duplicates()`.
- O7: preserve `get_search_results()` signature and `(queryset, bool)` return
  contract.

## Formal model

The K core is:

- `mini-admin-search.k`: a mini semantics for the admin search builder.
- `admin-search-spec.k`: K reachability claims for empty and nonempty token
  streams.

The model abstracts away database execution and concrete SQL generation, but it
keeps the property under audit visible: the Boolean predicate structure and the
number of queryset filter applications.

## Function contract

For finite `search_fields` and finite terms from `smart_split(search_term)`:

- If there are no terms, no search filter is applied and duplicate detection is
  still computed from lookup paths when search is active.
- If there is at least one term, exactly one queryset filter application is made
  with all per-term `Q` clauses.
- Each per-term clause is an OR of all constructed lookup predicates for that
  term.
- The final predicate is an AND of those per-term OR clauses.
- The duplicate flag is true exactly when any constructed lookup path can spawn
  duplicates.

## Source-level V2

V2 collects `or_queries` in `term_queries` during the token loop and applies
them once:

```python
if term_queries:
    queryset = queryset.filter(*term_queries)
```

This satisfies O3/O4/O5 and removes V1's unnecessary nested `Q(*term_queries)`
wrapper while keeping the same one-filter behavior.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases the K claims. `SPEC_AUDIT.md` compares that
paraphrase to the intent-only obligations. All required obligations pass. The
only ambiguity is the legacy chained-filter behavior across multi-valued
relations, recorded in `FINDINGS.md` as F-003 and rejected because the public
docs and issue support the single SQL predicate shape.
