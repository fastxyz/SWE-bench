requires "mini-matrix.k"

module COL-INSERT-SPEC
  imports MINI-MATRIX

  // SPEC-PROVENANCE:
  // - E5: "Insert one or more columns at the given column position."
  //   => result rows are preserved.
  claim <k> shapeRows(A, P, B) => resultInt(rows(specColInsert(A, P, B))) ... </k>
    requires rows(A) ==Int rows(B)
     andBool 0 <=Int P
     andBool P <=Int cols(A)
     andBool 0 <=Int cols(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: insertion adds the inserted column count.
  claim <k> shapeCols(A, P, B) => resultInt(cols(specColInsert(A, P, B))) ... </k>
    requires rows(A) ==Int rows(B)
     andBool 0 <=Int P
     andBool P <=Int cols(A)
     andBool 0 <=Int cols(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: entries before the insertion point are unchanged.
  claim <k> entry(A, P, B, I, J) => result(specEntry(A, P, B, I, J)) ... </k>
    requires rows(A) ==Int rows(B)
     andBool 0 <=Int I
     andBool I <Int rows(A)
     andBool 0 <=Int P
     andBool P <=Int cols(A)
     andBool 0 <=Int cols(B)
     andBool 0 <=Int J
     andBool J <Int P
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E5: inserted columns occupy the interval starting at P.
  claim <k> entry(A, P, B, I, J) => result(specEntry(A, P, B, I, J)) ... </k>
    requires rows(A) ==Int rows(B)
     andBool 0 <=Int I
     andBool I <Int rows(A)
     andBool 0 <=Int P
     andBool P <=Int cols(A)
     andBool 0 <=Int cols(B)
     andBool P <=Int J
     andBool J <Int P +Int cols(B)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: the identity block to the right of the inserted columns must keep
  //   its row placement.
  // - E4: "pos" should not be subtracted in this source-column mapping.
  claim <k> entry(A, P, B, I, J) => result(specEntry(A, P, B, I, J)) ... </k>
    requires rows(A) ==Int rows(B)
     andBool 0 <=Int I
     andBool I <Int rows(A)
     andBool 0 <=Int P
     andBool P <=Int cols(A)
     andBool 0 <=Int cols(B)
     andBool P +Int cols(B) <=Int J
     andBool J <Int cols(A) +Int cols(B)
    [all-path]
endmodule
