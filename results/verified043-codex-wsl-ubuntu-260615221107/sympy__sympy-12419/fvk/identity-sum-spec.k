requires "mini-sympy-identity.k"

module IDENTITY-SUM-SPEC
  imports MINI-SYMPY-IDENTITY

  // SPEC-PROVENANCE:
  // - E1/E2/E5: identity diagonal entries are one.
  claim <k> identityEntry(I:Int, I:Int, eq) => one ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E5: definite off-diagonal identity entries are zero.
  claim <k> identityEntry(I:Int, J:Int, neq) => zero ... </k>
    requires I =/=Int J
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4/E5: undecidable symbolic equality must not collapse to zero.
  claim <k> identityEntry(I:Int, J:Int, unknown) => kdSym ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E7: exact interval Piecewise support over the same bounds sums its active branch.
  claim <k> evalSumExactInterval(one, A:Int, B:Int) => B -Int A +Int 1 ... </k>
    requires B -Int A >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: total sum over all entries of Identity(n) is n for positive integer n.
  claim <k> nestedIdentitySum(N:Int) => N ... </k>
    requires N >=Int 1
    [all-path]
endmodule

