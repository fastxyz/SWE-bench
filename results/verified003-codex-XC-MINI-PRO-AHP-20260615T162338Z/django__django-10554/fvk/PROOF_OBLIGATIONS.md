# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

The obligations are written for the abstract `QueryState` model in `fvk/SPEC.md`.
They are K-style reachability and invariant obligations, recorded in Markdown per
the task's requested five-artifact output.

## PO1 - Clone Preservation

Claim:

```
<k> Clone(Q) => Qc </k>
requires finiteCombinedTree(Q)
ensures equivalentQueryTree(Q, Qc)
```

Meaning: cloning a query preserves the SQL-relevant field values of the top-level
query and all component queries. For `combined_queries`, preservation is recursive:
each cloned component is equivalent to the original component.

Evidence: `Query.clone()` already copies or clones mutable fields such as
`alias_refcount`, `alias_map`, `where`, masks, and relation maps. V1 adds the
missing recursive clone for `combined_queries`.

## PO2 - Combined Query Isolation

Claim:

```
<k> Clone(Q) => Qc </k>
requires finiteCombinedTree(Q)
ensures ids(ReachCombined(Q)) intersect ids(ReachCombined(Qc)) == empty
```

Meaning: after cloning a combined query, no component query reachable from the
clone is the same mutable object as a component query reachable from the source.

Evidence: V1 assigns `obj.combined_queries = tuple(query.clone() for query in
self.combined_queries)`. Each `query.clone()` returns a fresh `Query` object and
recursively satisfies PO2 for nested combined queries.

## PO3 - Mutation Frame for Derived Querysets

Claim:

```
<k> Clone(Q) ~> ProjectForValues(Qc, Cols) => .K </k>
requires finiteCombinedTree(Q)
ensures selectShapes(ReachCombined(Q)) == old(selectShapes(ReachCombined(Q)))
```

Meaning: branch projection performed through a derived clone cannot change the
branch select lists of the original combined queryset.

Evidence: PO2 gives disjoint component identities. Mutations through
`ProjectForValues(Qc, Cols)` target only identities reachable from `Qc`, so they
cannot update identities reachable from `Q`.

## PO4 - Issue-Specific Order Position Validity

Claim:

```
<k> Clone(Q) ~> ProjectForValues(Qc, [pk]) ~> Eval(Q) => SqlOk </k>
requires finiteCombinedTree(Q)
  and originalBranchWidth(Q) == W
  and orderPosition(Q) == P
  and 1 <= P and P <= W
ensures originalBranchWidth(Q) == W and P <= originalBranchWidth(Q)
```

Meaning: evaluating a derived projected queryset cannot narrow the original
union branches. Therefore an ordering position that was valid for the original
full-width union remains valid when the original queryset is evaluated again.

Evidence: the issue's failing SQL had an ordering position from the original
full-width select list, but a narrowed one-column branch select list. PO3 rules
out that state after V1.

## PO5 - Compatibility

Claim:

```
publicSignature(Query.clone) == old(publicSignature(Query.clone))
and publicSignature(Query.chain) == old(publicSignature(Query.chain))
and querysetResultProtocol == old(querysetResultProtocol)
```

Meaning: the fix must not require caller changes.

Evidence: V1 changes only internal clone ownership and does not alter signatures,
method names, return shape, or queryset public methods.

## PO6 - Nested Combined Query Induction

Claim:

```
finiteCombinedTree(Q) implies
  equivalentQueryTree(Q, Clone(Q))
  and disjointReach(Q, Clone(Q))
```

Proof shape: structural induction on the finite `combined_queries` tree.

Base case: `Q.combined_queries` is empty. `Clone(Q)` has no reachable component
queries, so disjointness holds vacuously and existing clone field copies provide
equivalence.

Inductive step: `Q.combined_queries = (C1, ..., Cn)`. V1 sets
`Clone(Q).combined_queries = (Clone(C1), ..., Clone(Cn))`. Freshness of each
direct clone plus the induction hypothesis for each `Ci` gives recursive
equivalence and disjointness.

## PO7 - Verification Boundary and Commands Not Run

Claim:

```
constructedProofOnly == true
```

Meaning: the FVK proof is constructed from source inspection and formal reasoning
only. It is not machine-checked in this workspace.

Commands that would be written for a separate machine-checkable K package, but
were not executed here:

```sh
kompile mini-query-clone.k --backend haskell
kast --backend haskell query-clone-spec.k
kprove query-clone-spec.k
```

Expected result if a complete K package matching this abstract model is supplied:
`kprove` discharges PO1-PO6 to `#Top`.
