requires "mini-sympy-quantum.k"

module IDENTITY-DAGGER-SPEC
  imports MINI-SYMPY-QUANTUM

  // SPEC-PROVENANCE:
  // - E1/E2: issue reports Dagger(A) * IdentityOperator() retains identity.
  // - obligation: direct multiplication returns Dagger(A).
  claim <k> daggerMul(dagger(op(A:Id)), idOp(N:Int)) => dagger(op(A)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: IdentityOperator docstring states op * I == I * op == op.
  // - obligation: symmetric direct multiplication returns Dagger(A).
  claim <k> identityMul(idOp(N:Int), dagger(op(A:Id))) => dagger(op(A)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E4: existing public behavior A * IdentityOperator() == A.
  // - obligation: preserve existing Operator.__mul__ identity behavior.
  claim <k> operatorMul(op(A:Id), idOp(N:Int)) => op(A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E4: existing public behavior IdentityOperator() * O == O.
  // - obligation: preserve existing IdentityOperator.__mul__ operator behavior.
  claim <k> identityMul(idOp(N:Int), op(A:Id)) => op(A) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: non-operator operands must not be consumed by quantum identity.
  // - obligation: a dagger around a non-operator remains generic multiplication.
  claim <k> daggerMul(dagger(nonOp(X:Id)), idOp(N:Int)) => mul(dagger(nonOp(X)), idOp(N)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: public test keeps IdentityOperator() * x as Mul.
  // - obligation: non-operator right operand remains generic multiplication.
  claim <k> identityMul(idOp(N:Int), nonOp(X:Id)) => mul(idOp(N), nonOp(X)) </k>
    [all-path]
endmodule
