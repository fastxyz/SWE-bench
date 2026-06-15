# FVK Spec: django__django-10554

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 source change in `repo/django/db/models/sql/query.py`:
`Query.clone()` now recursively clones `combined_queries`.

The proof target is the ownership property needed by the public issue: deriving and
evaluating a queryset from an ordered `union()` queryset must not mutate the original
combined queryset's component queries.

## Intent-Only Obligations

I1. Queryset derivation is non-mutating. A queryset produced from another queryset,
such as `qs.order_by().values_list('pk', flat=True)`, must not change the later
behavior of `qs`.

I2. For combined querysets, the non-mutation guarantee includes the component
queries inside `Query.combined_queries`, not only the top-level `Query` object.

I3. The issue-specific observable is SQL validity for the original ordered union:
after a derived projected queryset is evaluated, the original queryset's ordering
must still refer to a selected column in each union branch.

I4. The fix must be production-source-only and must not change public method
signatures, queryset result shapes, or test files.

## Public Evidence Ledger

E1. Source: `benchmark/PROBLEM.md`.
Quote: "Union queryset with ordering breaks on ordering with derived querysets".
Obligation: a derived queryset must not break later evaluation of the original
ordered union queryset. Status: encoded by I1 and I3.

E2. Source: `benchmark/PROBLEM.md`.
Quote: "`qs.order_by().values_list('pk', flat=True)`" followed by "`qs` [breaks]".
Obligation: the reproducer is specifically a derived projection from a combined
queryset. Status: encoded by I2 and I3.

E3. Source: `benchmark/PROBLEM.md`.
Quote: "ORDER BY position 4 is not in select list".
Obligation: the original ordered union's branch select list must not be narrowed
out from under the original ordering. Status: encoded by I3.

E4. Source: public Django queryset API shape and local implementation.
Quote: `QuerySet._clone()` creates a new `QuerySet` using `self.query.chain()`.
Obligation: `Query.chain()` and `Query.clone()` are the clone boundary where
mutable query ownership must be separated. Status: encoded by C1-C3.

E5. Source: task constraints.
Quote: "Do not modify any test files" and "do not attempt to run tests, Python,
or K framework tooling".
Obligation: source-only fix; proof and verification are reasoned artifacts only.
Status: encoded by I4 and all artifact caveats.

## Abstract Model

The FVK model abstracts a Django `Query` to the fields relevant to this issue:

```
QueryState = {
  id: object identity,
  select_shape: FullModelColumns | Projected(columns),
  order_position: None | positive integer,
  combined_queries: finite tuple<QueryState>
}
```

`ReachCombined(Q)` is the transitive set of component queries reachable from
`Q.combined_queries`.

`Clone(Q)` models `Query.clone()` after V1:

```
Clone(Q):
  Qc = shallow field copy of Q
  Qc.id is fresh
  if Q.combined_queries is non-empty:
      Qc.combined_queries = tuple(Clone(C) for C in Q.combined_queries)
  other mutable fields already handled by existing clone code are copied or cloned
  return Qc
```

`ProjectForValues(Qc, cols)` models the compiler/setup effect of a derived
combined queryset with a limited selected column list: any branch query reached
from the derived clone may be adjusted to `Projected(cols)`.

This abstraction intentionally does not prove full SQL generation. It preserves
the observable axis required by the issue: component query ownership, select-list
width, and order-position validity.

## Contracts

C1. Clone preservation. For every finite `QueryState Q`, `Clone(Q)` preserves the
SQL-relevant values of `Q` and of every component query, before any later mutation.

C2. Clone isolation. For every finite `QueryState Q`, no query identity in
`ReachCombined(Clone(Q))` is also in `ReachCombined(Q)`.

C3. Mutation frame. For every finite `QueryState Q`, every mutation whose target
identity is in `ReachCombined(Clone(Q))` leaves every state in `ReachCombined(Q)`
unchanged.

C4. Issue postcondition. If an original combined queryset `Q` has branch select
width `W` and an outer ordering position `P` with `1 <= P <= W`, then evaluating
a derived projected queryset created through `Clone(Q)` preserves the original
branches' select width `W`. Therefore the original ordering position `P` remains
in range.

C5. Compatibility. The production fix changes only `Query.clone()` internals and
does not change public signatures, return types, or test files.

## Adequacy Summary

The public issue is not asking for a different ordering rule or a different union
SQL shape. It asks that a derived queryset stop corrupting the original queryset.
The ownership contracts above directly express that requirement. They are neither
weaker than the issue, because they cover all component queries of a combined
queryset, nor stronger in a public API sense, because they preserve existing query
semantics and only alter internal clone ownership.
