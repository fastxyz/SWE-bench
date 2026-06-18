requires "mini-sqf-combine.k"

module SQF-COMBINE-OBLIGATIONS
  imports MINI-SQF-COMBINE

  // [ESCALATION BOUNDARY] OBL-GENERAL-GROUPING:
  // For every finite factor list FS, combineFactors(FS) contains exactly one
  // output entry for each (gens(poly), exponent) key appearing in FS, in the
  // order of the key's first occurrence.
  //
  // [ESCALATION BOUNDARY] OBL-GENERAL-PRODUCT:
  // For every key K in FS, the output polynomial for K is the product, in input
  // order, of all input polynomials with key K.
  //
  // These obligations require a list-induction theory over Factors plus a
  // polynomial-product abstraction. They are not admitted as trusted lemmas.
  syntax Bool ::= groupedByKey(Factors, Factors) [function]

  claim
    <k> combineFactors(FS:Factors) => OUT:Factors ... </k>
    ensures groupedByKey(FS, OUT)
    [all-path]
endmodule
