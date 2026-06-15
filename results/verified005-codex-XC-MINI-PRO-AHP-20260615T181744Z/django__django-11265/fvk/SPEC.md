# FVK Spec

Status: constructed, not machine-checked. This spec audits the V1 fix for
`django__django-11265` using public issue text, Django docs, public source, and
the V1 patch. No tests, Python, K tooling, hidden data, internet, or evaluator
artifacts were used.

Supporting FVK adequacy artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-query.k`
- `fvk/django-11265-spec.k`

## Scope

The audited unit is the internal query rewrite path used when a negated lookup
over a multi-valued relation enters `Query.split_exclude()` and then
`Query.trim_start()`.

In scope:

- Filtered relation aliases in `exclude()` lookups.
- Preservation of `FilteredRelation.condition` in the inner anti-subquery.
- Existing trim behavior for unfiltered joins and left outer joins.

Out of scope:

- Full SQL engine semantics.
- Full Python semantics.
- Full Django ORM evaluation.
- Unsupported `FilteredRelation` condition shapes already rejected by
  `add_filtered_relation()`.

## Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E-001 | issue | "Using exclude on annotated FilteredRelation doesn't work" | `exclude()` must work with filtered relation annotations. |
| E-002 | issue | `Cannot resolve keyword 'book_alice' into field` | Inner split query must resolve filtered aliases. |
| E-003 | issue | "A new query is created without all extra datas" | Copy relevant filtered relation metadata to the inner query. |
| E-004 | hint | "generated SQL doesn't use the FilteredRelation" | Alias resolution alone is insufficient. |
| E-005 | hint | Rob remains when only Alice should remain | Anti-subquery must include both predicates. |
| E-006 | hint | appropriate query has inner `WHERE book.title LIKE ...` | Relation-only filtered condition may be pushed into subquery `WHERE`. |
| E-007 | docs | `exclude()` returns objects that do not match lookups | Preserve logical anti-match semantics. |
| E-008 | docs | `FilteredRelation` acts on the annotation name | Annotation lookup carries filtered relation condition. |
| E-009 | docs | nested conditions unsupported | Do not expand public API/domain. |

## Intended Contract

For an outer query `Q` with `_filtered_relations[A] = FilteredRelation(R, C)`,
and an `exclude(A__L = V)` lookup that reaches `split_exclude()`:

1. The inner query created by `split_exclude()` can resolve `A`.
2. The inner query selects exactly the parent keys of related rows satisfying
   both `C` and `L = V`.
3. The outer exclude keeps exactly the outer objects whose keys are not in that
   selected key set, modulo the existing nullable-relation logic.
4. If `trim_start()` removes the join object that carried `C` in an `ON`
   clause, it must preserve `C` either by moving it into `WHERE` or by keeping
   the join when moving would make an alias reference invalid.
5. Unfiltered relation excludes and public method signatures remain unchanged.

## Formal Claims

The K claims are in `fvk/django-11265-spec.k`.

- `CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS`
- `CLAIM-TRIM-MOVES-FILTERED-CONDITION`
- `CLAIM-TRIM-KEEPS-PARENT-ALIAS-CONDITION`
- `CLAIM-UNFILTERED-FRAME`

The plain-English round trip in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent entries according to `fvk/SPEC_AUDIT.md`.

## V1 Adequacy Verdict

V1 satisfies the formalized intent:

- `query._filtered_relations = self._filtered_relations.copy()` at
  `query.py:1669` discharges alias-resolution intent.
- The `trim_start()` branch at `query.py:2149-2176` discharges predicate
  preservation by moving safe filtered predicates into `WHERE` and keeping the
  join when a predicate needs a trimmed alias.
- The changes are conditional and do not alter public signatures.

No further source edit is required by this FVK audit.

