requires "mini-sympy-factor.k"

module DMP-EXT-FACTOR-SPEC
  imports MINI-SYMPY-FACTOR
  imports K-EQUAL
  imports BOOL
  imports INT

  // SPEC-PROVENANCE:
  // - from_prompt: "Factor with extension=True drops a factor of y-1"
  //   => lower-variable factors must be preserved.
  // - from_prompt: "(x-1)*(y-1)" should factor as both factors, not "x - 1".
  // - from_code: V1 splits monic F into content G and primitive P, factors G
  //   recursively, and runs the norm path on P only.
  // - helper_contracts: dmp_primitive, dmp_factor_list, and dmp_trial_division
  //   satisfy the algebraic product obligations listed in PROOF_OBLIGATIONS.md.
  claim
    <k> dmpExtFactor(inputPoly, U:Int, K:Domain)
      => result(C:Poly, FS:FactorList) ... </k>
    requires U >Int 0
     andBool isAlgebraic(K)
     andBool notBool isConstant(monic(inputPoly, U, K), U, K)
    ensures { mul(C, prod(FS)) #Equals inputPoly }
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the missing factor y - 1 is content in the lower variable.
  // - from_code: factors from dmp_factor_list(G, u - 1, K) are lifted as [g].
  claim
    <k> dmpExtFactor(inputPoly, U:Int, K:Domain)
      => result(C:Poly, FS:FactorList) ... </k>
    requires U >Int 0
     andBool isAlgebraic(K)
     andBool notBool isConstant(monic(inputPoly, U, K), U, K)
    ensures { FS #Equals
      sortFactors(append(
        liftAll(contentFactors(content(monic(inputPoly, U, K), U, K), U -Int 1, K)),
        primitiveFactors(monic(inputPoly, U, K), primitive(monic(inputPoly, U, K), U, K), U, K))) }
    [all-path]
endmodule

