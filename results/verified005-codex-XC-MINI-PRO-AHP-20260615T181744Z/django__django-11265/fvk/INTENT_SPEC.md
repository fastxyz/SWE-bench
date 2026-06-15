# Intent Spec

Status: constructed from public issue text, Django docs, public source, and
V1 source. No tests, Python, K tooling, internet, hidden data, or evaluator
artifacts were used.

## Required behavior

I-001. `exclude()` on an annotated `FilteredRelation` must accept lookups that
start with the filtered relation annotation name. It must not raise
`FieldError: Cannot resolve keyword '<alias>' into field` solely because the
lookup is processed inside the `split_exclude()` subquery.

I-002. The excluded related rows must be rows satisfying both:

- the lookup predicate supplied to `exclude()`, for example
  `book_alice__title__contains="Jane"`; and
- the `FilteredRelation.condition`, for example
  `Q(book__title__startswith='The book by')`.

I-003. For a multi-valued relation, `exclude(alias__lookup=value)` is correctly
represented as an anti-subquery: keep the outer object iff its primary key is
not among parent keys selected from related rows satisfying I-002, with the
existing nullable-relation handling preserved.

I-004. `trim_start()` may simplify the inner subquery by making the related
table the subquery base table, but this rewrite must preserve the filtered
relation predicate. If the filtered predicate can be expressed against aliases
that remain after trimming, it may be moved from the filtered join `ON` clause
to the inner query `WHERE` clause.

I-005. If a filtered relation predicate references an alias that would be
trimmed away, `trim_start()` must not drop that alias and must leave the join
intact so the predicate remains meaningful in the `ON` clause.

I-006. Existing `split_exclude()` behavior for unfiltered relations, outer joins,
nullable selected fields, `F()` right-hand sides, and alias-reuse correlation
must remain unchanged except where needed to satisfy I-001 through I-005.

I-007. No public API, method signature, test file, or documented unsupported
`FilteredRelation` case should change.

