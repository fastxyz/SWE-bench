module MINI-SQF-COMBINE-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // Poly is an abstraction of a SymPy Poly value.
  // atom(G, N) means an atomic factor with generator tuple key G.
  // pprod(P1, P2) records multiplication without expanding coefficients.
  syntax Poly ::= atom(Int, Int)
                | pprod(Poly, Poly)

  syntax Factor ::= fac(Poly, Int)
  syntax Factors ::= ".Factors"
                   | Factor ";;" Factors [right]

  syntax Method ::= "sqf" | "factor"
  syntax KResult ::= Factors
endmodule

module MINI-SQF-COMBINE
  imports MINI-SQF-COMBINE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  syntax Int ::= gens(Poly) [function]
  rule gens(atom(G:Int, _:Int)) => G
  rule gens(pprod(P:Poly, _:Poly)) => gens(P)

  syntax Bool ::= sameKey(Factor, Factor) [function]
  rule sameKey(fac(P1:Poly, E1:Int), fac(P2:Poly, E2:Int))
    => gens(P1) ==Int gens(P2) andBool E1 ==Int E2

  syntax Poly ::= pmul(Poly, Poly) [function]
  rule pmul(P1:Poly, P2:Poly) => pprod(P1, P2)

  syntax Factors ::= combineFactors(Factors) [function]
  syntax Factors ::= combineAcc(Factors, Factors) [function]
  syntax Factors ::= appendOrMul(Factor, Factors) [function]

  rule combineFactors(FS:Factors) => combineAcc(FS, .Factors)

  rule combineAcc(.Factors, ACC:Factors) => ACC
  rule combineAcc(F:Factor ;; REST:Factors, ACC:Factors)
    => combineAcc(REST, appendOrMul(F, ACC))

  rule appendOrMul(F:Factor, .Factors) => F ;; .Factors

  rule appendOrMul(fac(P:Poly, E:Int), fac(P0:Poly, E0:Int) ;; REST:Factors)
    => fac(pmul(P0, P), E0) ;; REST
    requires sameKey(fac(P, E), fac(P0, E0))

  rule appendOrMul(F:Factor, F0:Factor ;; REST:Factors)
    => F0 ;; appendOrMul(F, REST)
    requires notBool sameKey(F, F0)

  // Model of the V1 dispatch point in _generic_factor_list:
  // sqf factors are combined; ordinary factor-list factors are not.
  syntax Factors ::= normalizeFactors(Method, Factors) [function]
  rule normalizeFactors(sqf, FS:Factors) => combineFactors(FS)
  rule normalizeFactors(factor, FS:Factors) => FS
endmodule
