requires "mini-python-vector.k"

module VECTOR-ADD-SPEC-SYNTAX
  imports MINI-PYTHON-VECTOR-SYNTAX
endmodule

module VECTOR-ADD-SPEC
  imports MINI-PYTHON-VECTOR

  // SPEC-PROVENANCE:
  // - E1/E4: "vector add 0 error" and the public hint
  //   "#if other == 0: return self" require scalar zero to be the additive
  //   identity on the Vector.__add__ path.
  claim <k> vectorAdd(Vec(Cs:Comps), 0) => Vec(Cs) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E6/E10: Python sum starts with scalar 0, and Vector.__radd__ is an
  //   alias for __add__, so 0 + vector must dispatch to the zero-identity path.
  claim <k> pyAdd(0, Vec(Cs:Comps)) => Vec(Cs) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Required frame condition: existing vector-plus-vector behavior is
  //   preserved when the other operand is already a Vector.
  claim <k> vectorAdd(Vec(Cs:Comps), Vec(Ds:Comps)) => Vec(merge(Cs, Ds)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: Vector(0) is the zero vector, and multiplying a vector by scalar
  //   zero constructs that zero vector.
  claim <k> mul(0, Vec(Cs:Comps)) => Vec(.Comps) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: the public reproducer sum([N.x, 0 * N.x]) must return N.x rather
  //   than raising TypeError.
  claim <k> sum2(Vec(Cs:Comps), mul(0, Vec(Cs))) => Vec(Cs) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8/E9: _check_vector still rejects non-Vector operands. V1 must not turn
  //   vector addition into general scalar addition.
  claim <k> vectorAdd(Vec(Cs:Comps), I:Int) => TypeError </k>
    requires I =/=Int 0
    [all-path]
endmodule
