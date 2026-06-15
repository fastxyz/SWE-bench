# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Filtered alias resolution in `split_exclude()`

Public intent: E-001, E-002, E-003.

Obligation: If the outer query has `_filtered_relations[A]`, then the fresh
inner query created by `split_exclude()` must also have `_filtered_relations[A]`
before `query.add_filter((A__lookup, value))`.

Candidate evidence: `repo/django/db/models/sql/query.py:1668-1670`.

Formal claim: `CLAIM-SPLIT-EXCLUDE-COPIES-FILTERED-RELATIONS`.

Expected result: no FieldError from alias absence.

## PO-2: Filtered condition preservation during trim

Public intent: E-004, E-005, E-006, E-007, E-008.

Obligation: If `trim_start()` converts a filtered join into the subquery base
table, the `FilteredRelation.condition` stored on that join must still constrain
the inner selected parent keys.

Candidate evidence: `repo/django/db/models/sql/query.py:2151-2168`.

Formal claim: `CLAIM-TRIM-MOVES-FILTERED-CONDITION`.

Expected result: the public Rob example is represented as an anti-subquery over
books whose title both starts with "The book by" and contains "Jane".

## PO-3: Alias-safety guard for moved predicates

Public intent: I-005 and compatibility with valid SQL alias references.

Obligation: If a filtered relation condition references an alias that would be
trimmed away, the first join must remain so the predicate can stay in the `ON`
clause.

Candidate evidence: `repo/django/db/models/sql/query.py:2161-2170`.

Formal claim: `CLAIM-TRIM-KEEPS-PARENT-ALIAS-CONDITION`.

Expected result: V1 does not create a `WHERE` predicate that references a
removed alias.

## PO-4: Frame unfiltered and outer-join behavior

Public intent: I-006, I-007.

Obligation: Existing `trim_start()` behavior for unfiltered first joins and
left outer joins remains unchanged.

Candidate evidence: the new branch is guarded by `first_join.filtered_relation`;
the existing `LOUTER` branch remains unchanged.

Formal claim: `CLAIM-UNFILTERED-FRAME`.

Expected result: ordinary multi-valued `exclude()` query rewrites are not
changed by this fix.

## PO-5: Public compatibility

Public intent: E-009, I-007.

Obligation: Do not change public method signatures, return shapes, unsupported
`FilteredRelation` validation, or tests.

Candidate evidence: diff changes only internal bodies in
`repo/django/db/models/sql/query.py`; no test files are modified.

Formal artifact: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Expected result: compatibility pass.

