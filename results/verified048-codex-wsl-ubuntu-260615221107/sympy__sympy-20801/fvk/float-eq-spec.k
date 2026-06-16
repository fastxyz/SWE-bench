requires "mini-sympy-eq.k"

module FLOAT-EQ-SPEC
  imports MINI-SYMPY-EQ

  // SPEC-PROVENANCE:
  // - E1/E2/E3/E4: SymPy Boolean false is not numeric zero.
  claim
    <k> floatEq(floatZero, symFalse) => eqFalse </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4 and existing source guard: all already-SymPy Booleans are unequal to
  //   Float values, not only zero Float.
  claim
    <k> floatEq(floatNonZero, symFalse) => eqFalse </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: native Python False is not the same public input as S.false before
  //   sympification; V1 must not broaden the issue fix to that input.
  claim
    <k> floatEq(floatZero, pyFalse) => eqTrue </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - PO3 frame: numeric zero remains equal to zero Float.
  claim
    <k> floatEq(floatZero, numZero) => eqTrue </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - PO5 frame: unsympifiable non-Boolean operands do not become equal.
  claim
    <k> floatEq(floatZero, unsympifiable) => notImplemented </k>
    [all-path]
endmodule
