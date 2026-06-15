# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Theorem

For every finite Django `Query` tree representing a combined queryset, V1
`Query.clone()` returns an equivalent clone whose `combined_queries` descendants
are disjoint mutable objects from the source query's `combined_queries`
descendants. Consequently, evaluating a derived projected combined queryset
cannot narrow the original combined queryset's branch select list, so the
original ordered union cannot later fail with an out-of-range `ORDER BY`
position because of that derivation.

This proves PO1-PO4 over the abstract model in `fvk/SPEC.md`.

## Proof Sketch

Before V1, `Query.clone()` performed `obj.__dict__ = self.__dict__.copy()` and
then copied or cloned many mutable fields. It did not replace `combined_queries`.
For a combined query `Q` with child query `C`, the clone `Qc` therefore had a
component tuple containing the same `C`. A later projection operation on a
derived combined queryset could target `C`, changing the branch select shape
used by the original `Q`. That state explains the issue symptom: the original
query keeps an outer ordering position such as `4`, while the shared branch has
been narrowed to a one-column `pk` projection.

V1 adds:

```
if self.combined_queries:
    obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

Base case for PO6: if `Q.combined_queries` is empty, cloning introduces no
component descendants. Disjointness of component descendants is trivial, and the
existing clone logic preserves the non-combined query fields.

Inductive step for PO6: assume every component query `Ci` in
`Q.combined_queries` has a clone `Clone(Ci)` that is equivalent to `Ci` and has
component descendants disjoint from `Ci`. V1 constructs
`Clone(Q).combined_queries` exactly as the tuple of those `Clone(Ci)` values.
Each direct `query.clone()` returns a fresh `Query` object, and the induction
hypothesis gives recursive freshness for nested combined queries. Therefore
`ReachCombined(Clone(Q))` and `ReachCombined(Q)` are disjoint while preserving
SQL-relevant values.

PO1 follows from the existing field-copy behavior plus the new recursive
combined-query clone. PO2 follows from the fresh direct clones and the PO6
induction. PO3 follows by frame reasoning: a mutation keyed by an identity in
`ReachCombined(Clone(Q))` cannot alter any identity in `ReachCombined(Q)` when
the two identity sets are disjoint. PO4 follows by instantiating PO3 with the
issue path: derive `Qc = Clone(Q)`, evaluate a projected `values_list('pk')`
query through `Qc`, and then evaluate `Q`. The projection can narrow only clone
branches, so the original branches keep width `W`; a previously valid order
position `P <= W` remains valid.

PO5 holds because the source edit changes only the internal body of
`Query.clone()` and leaves public signatures and queryset protocols unchanged.

## Adequacy Check

The proof does not choose a new ordering policy, SQL syntax, or backend-specific
compound-query rule. It proves the public-intent property that a derived queryset
does not mutate the original combined queryset. That property is exactly the
reported failure class in `benchmark/PROBLEM.md`.

## Residual Risk

This is a partial, abstract proof over the ownership property. It does not model
the complete Django SQL compiler, all database backend feature flags, or
termination/performance of all queryset operations. Those remain covered by
Django's test suite and by future machine-checking outside this no-execution
workspace.

## Machine-Check Commands Not Run

The following commands are the intended K-tooling shape for a separate complete
K package for this abstract model. They were not executed.

```sh
kompile mini-query-clone.k --backend haskell
kast --backend haskell query-clone-spec.k
kprove query-clone-spec.k
```

Expected machine-check result for PO1-PO6: `#Top`.

## Test Guidance

No tests were run and no test files were modified. Existing and hidden regression
tests should be kept until normal CI and any future machine-checking run. A useful
regression test would construct an ordered union queryset, evaluate a derived
`order_by().values_list('pk', flat=True)` queryset, then evaluate the original
queryset and assert it still succeeds.
