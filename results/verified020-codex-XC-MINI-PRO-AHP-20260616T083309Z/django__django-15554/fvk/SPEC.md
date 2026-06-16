# FVK Spec: FilteredRelation Join Reuse

Status: constructed for audit, not machine-checked.

## Target

The audited behavior is the join-reuse policy used by:

- `repo/django/db/models/sql/query.py::Query.join()`
- `repo/django/db/models/sql/query.py::Query.setup_joins()`
- `repo/django/db/models/sql/query.py::Query.build_filter()`
- `repo/django/db/models/sql/query.py::Query.build_filtered_relation_q()`
- `repo/django/db/models/query_utils.py::FilteredRelation.as_sql()`
- `repo/django/db/models/sql/datastructures.py::Join.__eq__()` and `Join.equals()`

The observable behavior is whether a query using multiple `FilteredRelation`
aliases on the same relation path receives one SQL JOIN per distinct filtered
alias, while still letting each filtered relation's own ON-clause condition
resolve against the join currently being compiled.

## Intent Spec

1. A `FilteredRelation` annotation creates an ON-clause filter for the annotated
   relation alias when a JOIN is needed.
2. Multiple `FilteredRelation` annotations for the same relation path are
   independent when their filtered relation identity differs, including
   different aliases or different `Q()` conditions.
3. Two independent filtered aliases for the same relation path must not collapse
   into one join; later references to each alias must bind to the corresponding
   join.
4. While compiling a filtered relation's own ON-clause condition, lookups through
   the underlying relation name must reuse the filtered relation path being
   compiled. They must not create an extra unfiltered join.
5. Existing ordinary join reuse remains valid: a repeated reference to the same
   join identity may reuse an existing alias, and many-to-many reuse remains
   governed by the caller-provided reuse set.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Using multiple FilteredRelation with different filters but for same relation is ignored." | The reported legacy behavior is a bug, not a behavior to preserve. | Encoded in PO-NORMAL-DISTINCT. |
| E2 | prompt | "I would only see a join for relation_zone. Not for relation_all." | Distinct filtered aliases on the same relation path must both produce joins when both are referenced. | Encoded in PO-NORMAL-DISTINCT and PO-SQL-OBSERVABLE. |
| E3 | prompt | The example uses `relation_zone=FilteredRelation(...zone=F("zone"))` and `relation_all=FilteredRelation(...is_all=True)` on `"myrelation__nested"`. | The family includes same relation path, different conditions, and references through both aliases. | Encoded in PO-NORMAL-DISTINCT. |
| E4 | public hint | Regression test expects `book_title_alice` and `book_title_jane` on `"book"` to produce different result columns. | Same relation path with different filters must keep alias-specific semantics. | Encoded in PO-NORMAL-DISTINCT. |
| E5 | docs | "`FilteredRelation` is used with `QuerySet.annotate()` to create an `ON` clause when a `JOIN` is performed." | The filter belongs to the JOIN, so distinct ON filters are semantically distinct joins. | Encoded in PO-SQL-OBSERVABLE. |
| E6 | docs | "It doesn't act on the default relationship but on the annotation name." | References to the annotation name must select that alias, not the default relation or another alias. | Encoded in PO-ALIAS-BINDING. |
| E7 | implementation | `Join.identity` includes `filtered_relation`; `Join.equals()` ignores it. | The implementation already distinguishes strong and weak equality; the proof must use the right predicate in the right phase. | Encoded in PO-EQUALITY-MODE. |
| E8 | implementation | `FilteredRelation.as_sql()` calls `build_filtered_relation_q(..., reuse=set(self.path))`. | ON-clause condition resolution has a known path-reuse context. | Encoded in PO-FILTERED-PATH-REUSE. |

## Formal Model

The formal model abstracts away SQL rendering details and keeps the property
axis that the issue measures: alias cardinality and alias-to-filter binding.

Definitions:

- `StrongEq(existing, candidate)` is `Join.__eq__()`: class, table name,
  parent alias, join field, and `filtered_relation` are all equal.
- `WeakEq(existing, candidate)` is `Join.equals()`: class, table name, parent
  alias, and join field are equal; `filtered_relation` is ignored.
- `Allowed(alias, reuse)` holds when `reuse is None` or `alias in reuse`.
- `JoinNormal(candidate, reuse)` returns an existing alias iff an allowed join
  has `StrongEq(existing, candidate)`; otherwise it creates a new alias.
- `JoinFilteredCondition(candidate, reuse)` returns an existing alias iff
  `reuse` is non-empty and contains an alias whose join has
  `WeakEq(existing, candidate)`; otherwise it creates a new alias.

## Formal Spec English

- Claim C1: In normal query construction, two candidate joins with the same
  relation path but different filtered relation aliases or conditions are not
  reusable, because their strong identities differ.
- Claim C2: In normal query construction, a repeated reference to the same
  filtered relation identity is reusable when allowed by `reuse`.
- Claim C3: In filtered-relation condition compilation, a condition lookup whose
  candidate join has the same structural relation path as an alias in the
  filtered relation's path reuses that path alias even though the candidate has
  no `filtered_relation` object.
- Claim C4: In filtered-relation condition compilation, aliases outside
  `reuse=set(filtered_relation.path)` are not reusable, even if weakly equal.
- Claim C5: If C1 holds and both aliases are referenced, the query alias map
  contains two filtered joins and SQL generation has both ON-clause filters as
  independent contributors.

## Spec Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| C1 | Pass | Directly matches E1-E4 and does not preserve the reported legacy collapse. |
| C2 | Pass | Matches existing alias reuse semantics and public tests that reference one filtered alias multiple times. |
| C3 | Pass | Required by E5/E8: ON-clause conditions must bind to the join being compiled. |
| C4 | Pass | Prevents weak equality from reintroducing global collapse during condition compilation. |
| C5 | Pass | Connects the local alias-map proof to the issue's SQL/result observable. |

No claim is derived only from V1 behavior. The only implementation-derived
terms are the state variables and equality predicates needed to model the code.

## Public Compatibility Audit

Changed symbols are internal methods on `Query`:

- `Query.join(join, reuse=None, reuse_with_filtered_relation=False)`
- `Query.build_filter(..., reuse_with_filtered_relation=False, check_filterable=True)`
- `Query.setup_joins(..., reuse_with_filtered_relation=False)`

Compatibility findings:

- Existing source callsites use keyword arguments or fewer positional arguments
  than the new parameter position requires.
- The new parameters have defaults, so existing internal callers keep their V1
  call behavior unless they opt into filtered-relation condition reuse.
- No public `FilteredRelation` API signature changed.
- No subclass or override of these internal methods was found under `repo/`.

## Domain And Limits

The proof is partial correctness over query-construction states where:

- `Join.identity`, `Join.__eq__()`, and `Join.equals()` have the meanings above.
- `FilteredRelation.__eq__()` compares relation name, alias, and condition, as
  implemented in `query_utils.py`.
- `FilteredRelation.as_sql()` supplies `reuse=set(self.path)` for its condition.

The proof does not model database execution, SQL quoting, or join promotion
semantics beyond the alias-map cardinality and alias binding needed for this
issue. Those are integration concerns to keep covered by existing tests.

