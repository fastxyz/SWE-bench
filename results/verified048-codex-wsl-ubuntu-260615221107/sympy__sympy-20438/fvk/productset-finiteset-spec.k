requires "mini-sympy-sets.k"

module PRODUCTSET-FINITESET-SPEC
  imports MINI-SYMPY-SETS

  // SPEC-PROVENANCE:
  // - E3: "is_subset doesn't work ProductSet.is_subset(FiniteSet)"
  // - finite-target set theory: a definitely non-finite product is not a subset of a finite set.
  claim <k> subset(PSet(finiteFalse, ER:EnumResult), FSet(ES:Elems)) => F </k>
    [label(PSUBSET-NONFINITE)]

  // SPEC-PROVENANCE:
  // - E6: undecidable symbolic set queries preserve fuzzy None.
  claim <k> subset(PSet(finiteUnknown, ER:EnumResult), FSet(ES:Elems)) => U </k>
    [label(PSUBSET-UNKNOWN-FINITE)]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: concrete finite products are decided by membership of every product element.
  claim <k> subset(PSet(finiteTrue, enum(ES:Elems)), FSet(TES:Elems)) => containsAll(ES, FSet(TES)) </k>
    [label(PSUBSET-FINITE-ENUM)]

  // SPEC-PROVENANCE:
  // - F2: finite status does not guarantee safe enumeration for symbolic/undecidable products.
  claim <k> subset(PSet(finiteTrue, enumTypeError), FSet(ES:Elems)) => U </k>
    [label(PSUBSET-FINITE-ENUM-TYPEERROR)]

  // SPEC-PROVENANCE:
  // - F2: symbolic Range-like finite products can fail with ValueError during enumeration.
  claim <k> subset(PSet(finiteTrue, enumValueError), FSet(ES:Elems)) => U </k>
    [label(PSUBSET-FINITE-ENUM-VALUEERROR)]

  // SPEC-PROVENANCE:
  // - E4/E5: equivalent product and finite set equality is mutual subsethood.
  claim <k> eqset(PSet(FF:FiniteFlag, ER:EnumResult), FSet(ES:Elems)) => tfn(and3(subset(PSet(FF, ER), FSet(ES)), subset(FSet(ES), PSet(FF, ER)))) </k>
    [label(PEQ-FSET)]

  // SPEC-PROVENANCE:
  // - E4/E5: same equality rule in the reverse argument order.
  claim <k> eqset(FSet(ES:Elems), PSet(FF:FiniteFlag, ER:EnumResult)) => tfn(and3(subset(FSet(ES), PSet(FF, ER)), subset(PSet(FF, ER), FSet(ES)))) </k>
    [label(FSET-PEQ)]
endmodule
