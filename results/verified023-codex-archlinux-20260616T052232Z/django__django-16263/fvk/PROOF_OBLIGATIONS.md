# FVK Proof Obligations

Status: constructed obligations; not machine-checked.

## Abstract K Model

The full Django ORM is outside the bundled FVK fragment, so the proof uses a
small abstract transition system over query metadata. The observable state is:

```k
configuration
  <k> $PGM:K </k>
  <annotations> .Map </annotations>
  <selected> .Set </selected>
  <deps> .Map </deps>
  <lookupRefs> .Set </lookupRefs>
  <aliasDelta> .Map </aliasDelta>
  <aliasRefcount> .Map </aliasRefcount>
  <groupBy> none </groupBy>
  <distinct> false </distinct>
  <distinctFields> .Set </distinctFields>
  <sliced> false </sliced>
  <combinator> false </combinator>
```

Run commands to machine-check a complete version in a real environment:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-prune-spec.k
kprove fvk/query-prune-spec.k --definition fvk/mini-django-query-kompiled
```

These commands are recorded only; they were not executed.

## PO1: Annotation Alias Delta Soundness

Claim:

```k
claim <k> addAnnotation(Alias, Expr) => . </k>
      <aliasRefcount> RC </aliasRefcount>
   => <annotations> ... Alias |-> resolve(Expr) ... </annotations>
      <aliasDelta> ... Alias |-> positiveDelta(RC, RC') ... </aliasDelta>
      <aliasRefcount> RC' </aliasRefcount>
```

Obligation: after annotation resolution, the recorded delta contains exactly the
positive alias reference-count increments caused by that annotation.

Justification source: SPEC I2 and FINDING F2.

## PO2: Lookup Reference Preservation

Claim:

```k
claim <k> solveLookup(Path) => annotationLookup(Alias, Rest) </k>
      <annotations> ... Alias |-> Expr ... </annotations>
      requires prefix(Alias, Path)
   => <lookupRefs> SetItem(Alias) ... </lookupRefs>
```

Obligation: a filter path that resolves through an annotation alias records that
alias as required.

Justification source: SPEC I3 and FINDING F3.

## PO3: Annotation Dependency Closure

Claim:

```k
claim <k> required(Roots) => closure(Roots, Deps) </k>
      <deps> Deps </deps>
```

Obligation: if required annotation `B` depends on annotation `A`, then `A` is
also required before pruning.

Justification source: SPEC I3 and FINDING F3.

## PO4: Prune Removes Only Non-Required Annotation Effects

Claim:

```k
claim <k> prune(PreserveSelected, PreserveOrdering) => . </k>
      <annotations> Ann </annotations>
      <aliasRefcount> RC </aliasRefcount>
      <aliasDelta> Delta </aliasDelta>
   => <annotations> restrict(Ann, Required) </annotations>
      <aliasRefcount> subtractDeltas(RC, Delta, Ann -Set Required) </aliasRefcount>
```

Obligation: every required annotation remains; every removed annotation subtracts
only its own recorded alias delta.

Justification source: SPEC I1, I2, I3 and FINDING F2.

## PO5: Cardinality Safety Boundaries

Claim:

```k
claim <k> requiredRoots => Roots </k>
      <distinct> true </distinct>
      <selected> Selected </selected>
   => <k> Roots includes Selected </k>

claim <k> requiredRoots => Roots </k>
      <selected> SetItem(Alias) ... </selected>
      <annotations> ... Alias |-> nonAggregateMultiValued ... </annotations>
   => <k> Roots includes SetItem(Alias) </k>
```

Obligation: selected annotations that can affect distinct row identity or
multi-valued row cardinality are retained.

Justification source: SPEC I2, I6 and FINDING F4.

## PO6: Group-By Cleanup

Claim:

```k
claim <k> prune(false, false) => . </k>
      <annotations> .Map </annotations>
      <groupBy> true </groupBy>
   => <groupBy> none </groupBy>
```

Obligation: if aggregate annotations were the only reason for `group_by=True`
and all annotations are pruned, grouped `exists()`/`count()` behavior does not
leak through.

Justification source: SPEC I1, I4.

## PO7: Count Contract

Claim:

```k
claim <k> getCount => count(Q') </k>
      <combinator> false </combinator>
   => <k> count(pruneUnused(Q)) </k>

claim <k> getCount => count(Q) </k>
      <combinator> true </combinator>
```

Obligation: non-combined count uses the pruning transition before adding
`Count("*")`; combined count skips pruning.

Justification source: SPEC I1, I2, I5 and FINDING F1.

## PO8: Exists Contract

Claim:

```k
claim <k> exists => existsQuery(pruneUnused(Q)) </k>
      <distinct> false </distinct>
      <sliced> false </sliced>
      <combinator> false </combinator>

claim <k> exists => existsQuery(Q) </k>
      <combinator> true </combinator>
```

Obligation: eligible non-combined existence queries prune unused annotations
before the existing select-clearing path; combined and distinct-sliced paths
preserve their current selected-column behavior.

Justification source: SPEC I4, I5 and FINDING F1.

## PO9: Public Compatibility

Obligation: the change must not alter public `QuerySet.count()` or
`QuerySet.exists()` signatures, return types, or test-file contracts.

Justification source: task constraints and Django API compatibility.

Result by inspection: signatures are unchanged; no test files were modified.
