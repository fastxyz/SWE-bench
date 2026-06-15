# Public Evidence Ledger

## E-001: Issue title

- Source: prompt / issue
- Evidence: "Using exclude on annotated FilteredRelation doesn't work"
- Obligation: `exclude()` must work with annotated `FilteredRelation` aliases.
- Encoded in: I-001, PO-1.

## E-002: Reported exception

- Source: prompt / issue
- Evidence: `FieldError: Cannot resolve keyword 'book_alice' into field.`
- Obligation: the subquery built by `split_exclude()` must resolve
  `book_alice` through `_filtered_relations`.
- Encoded in: I-001, PO-1.

## E-003: Fresh inner query cause

- Source: prompt / issue
- Evidence: "A new query is created without all extra datas from the original
  query."
- Obligation: the inner query needs the outer filtered relation metadata.
- Encoded in: I-001, PO-1.

## E-004: Copy-only patch is insufficient

- Source: prompt / public hint
- Evidence: "Even if the error is not there anymore, the generated SQL doesn't
  use the FilteredRelation."
- Obligation: preserving alias resolution is insufficient unless the filtered
  predicate remains in the subquery semantics.
- Encoded in: I-002, I-004, PO-2.

## E-005: Explicit wrong-result example

- Source: prompt / public hint
- Evidence: `exclude(book_alice__title__contains="Jane")` after
  `FilteredRelation('book', condition=Q(book__title__startswith='The book by'))`
  returns Alice and Rob, but should return only Alice.
- Obligation: the anti-subquery must exclude rows matching both the lookup and
  the filtered relation condition.
- Encoded in: I-002, I-003, PO-2.

## E-006: Correct anti-subquery shape

- Source: prompt / public hint
- Evidence: "I think the appropriate query should be ... WHERE NOT
  (`author`.`id` IN (SELECT `book`.`author_id` FROM `book` WHERE
  `book`.`title` LIKE 'poem by alice'))"
- Obligation: for relation-only filtered predicates, moving the filtered
  predicate into the inner subquery `WHERE` clause is valid and desired.
- Encoded in: I-003, I-004, PO-2.

## E-007: `exclude()` docs

- Source: `repo/docs/ref/models/querysets.txt`
- Evidence: "`exclude()` ... Returns a new QuerySet containing objects that do
  not match the given lookup parameters."
- Obligation: filtered relation exclude must implement negation of the filtered
  lookup, not an unfiltered relation lookup.
- Encoded in: I-002, I-003, PO-2.

## E-008: `FilteredRelation` docs

- Source: `repo/docs/ref/models/querysets.txt`
- Evidence: "`FilteredRelation` is used with `QuerySet.annotate()` to create an
  `ON` clause when a `JOIN` is performed. It doesn't act on the default
  relationship but on the annotation name."
- Obligation: lookups on the annotation name carry the filtered relation
  condition into the query semantics.
- Encoded in: I-001, I-002, PO-1, PO-2.

## E-009: Unsupported nested conditions remain unsupported

- Source: `repo/docs/ref/models/querysets.txt`
- Evidence: "`FilteredRelation` doesn't support: Conditions that span
  relational fields."
- Obligation: the fix must not expand the public domain of supported
  `FilteredRelation.condition` shapes.
- Encoded in: I-007, PO-5.

## E-010: V1 implementation evidence

- Source: source code
- Evidence: `split_exclude()` now copies `_filtered_relations`; `trim_start()`
  moves a filtered relation condition into `WHERE` only when it does not use a
  trimmed alias, otherwise it keeps the join.
- Obligation: candidate behavior to verify against I-001 through I-007.
- Encoded in: PO-1 through PO-5.

