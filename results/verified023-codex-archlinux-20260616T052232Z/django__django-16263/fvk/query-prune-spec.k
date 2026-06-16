requires "mini-django-query.k"

module QUERY-PRUNE-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - I1/I2: unused annotations should be stripped from count while preserving
  //   count cardinality.
  // - F2/PO1/PO4: alias deltas are needed because annotations can introduce
  //   joins that affect COUNT(*).
  claim <k> addAnnotation(Alias, Expr) => . </k>
        <annotations> Ann => Ann [ Alias <- Expr ] </annotations>
        <aliasRefcount> RC => RC' </aliasRefcount>
        <aliasDelta> Delta => Delta [ Alias <- positiveDelta(RC, RC') ] </aliasDelta>
    [all-path]

  // SPEC-PROVENANCE:
  // - I3/F3: annotation aliases referenced by filters are required.
  claim <k> solveLookup(Path) => . </k>
        <annotations> Ann </annotations>
        <lookupRefs> Refs => Refs SetItem(annotationPrefix(Path, Ann)) </lookupRefs>
    requires prefix(annotationPrefix(Path, Ann), Path)
    [all-path]

  // SPEC-PROVENANCE:
  // - I1/I2/I3/F2/F3/F4: pruning keeps the required closure and subtracts only
  //   removed annotations' alias deltas.
  claim <k> prune(PreserveSelected, PreserveOrdering) => . </k>
        <annotations> Ann => restrict(Ann, Required) </annotations>
        <aliasRefcount> RC => subtractDeltas(RC, Delta, keys(Ann) -Set Required) </aliasRefcount>
        <aliasDelta> Delta </aliasDelta>
        <lookupRefs> LookupRefs </lookupRefs>
        <selected> Selected </selected>
        <deps> Deps </deps>
        <distinct> Distinct </distinct>
        <sliced> Sliced </sliced>
      requires Required ==K closure(
          requiredRoots(Ann, LookupRefs, Selected, Deps, PreserveSelected, PreserveOrdering),
          Deps
        )
       andBool PreserveSelected ==Bool Distinct orBool PreserveSelected ==Bool false
       andBool PreserveOrdering ==Bool Sliced orBool PreserveOrdering ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - F1/PO7: combined count must skip pruning.
  claim <k> getCount => countWithoutPrune </k>
        <combinator> true </combinator>
    [all-path]

  // SPEC-PROVENANCE:
  // - I1/I2/PO7: non-combined count prunes before counting.
  claim <k> getCount => countAfterPrune </k>
        <combinator> false </combinator>
    [all-path]

  // SPEC-PROVENANCE:
  // - F1/PO8: combined exists must skip top-level pruning.
  claim <k> exists => existsWithoutTopLevelPrune </k>
        <combinator> true </combinator>
    [all-path]

  // SPEC-PROVENANCE:
  // - I4/PO8: eligible non-combined exists prunes before the existing
  //   select-clearing path.
  claim <k> exists => existsAfterPrune </k>
        <combinator> false </combinator>
        <distinct> false </distinct>
        <sliced> false </sliced>
    [all-path]
endmodule
