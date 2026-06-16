module MINI-SYMPY-FACTOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Poly
  syntax Domain
  syntax FactorList

  syntax Poly ::= inputPoly
                | monic(Poly, Int, Domain)        [function]
                | lc(Poly, Int, Domain)           [function]
                | content(Poly, Int, Domain)      [function]
                | primitive(Poly, Int, Domain)    [function]
                | lift(Poly)                      [function]
                | mul(Poly, Poly)                 [function]
                | pow(Poly, Int)                  [function]
                | prod(FactorList)                [function]
                | coeff(FactorList)               [function]
                | primitiveProduct(Poly, Int, Domain) [function]
                | one                            [function]

  syntax FactorList ::= contentFactors(Poly, Int, Domain) [function]
                      | primitiveFactors(Poly, Poly, Int, Domain) [function]
                      | liftAll(FactorList)          [function]
                      | append(FactorList, FactorList) [function]
                      | sortFactors(FactorList)      [function]

  syntax Bool ::= isAlgebraic(Domain) [function]
                | isConstant(Poly, Int, Domain) [function]
                | positiveDegree(Poly, Int, Domain) [function]

  syntax KItem ::= dmpExtFactor(Poly, Int, Domain)
                 | result(Poly, FactorList)
endmodule

module MINI-SYMPY-FACTOR
  imports MINI-SYMPY-FACTOR-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Abstract transition for the V1 branch of dmp_ext_factor.
  // Helper contracts are specified as proof obligations in dmp-ext-factor-spec.k.
  rule
    <k> dmpExtFactor(F:Poly, U:Int, K:Domain)
      => result(
           mul(lc(F, U, K), coeff(contentFactors(content(monic(F, U, K), U, K), U -Int 1, K))),
           sortFactors(append(
             liftAll(contentFactors(content(monic(F, U, K), U, K), U -Int 1, K)),
             primitiveFactors(monic(F, U, K), primitive(monic(F, U, K), U, K), U, K))))
       ... </k>
    requires U >Int 0
     andBool isAlgebraic(K)
     andBool notBool isConstant(monic(F, U, K), U, K)
endmodule

