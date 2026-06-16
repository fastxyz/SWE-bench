// Mini dense-polynomial semantics for the clear_denoms FVK audit.
// Status: constructed, not machine-checked.
//
// This is a deliberately small model of the operations relevant to the issue:
// denominator accumulation, ground multiplication, and dense canonicalization.
// It is not a full Python or full SymPy semantics.

module MINI-DENSE-POLYS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Coeff ::= "one" | "zero" | "latentZero" | "denLatentZero"
                 | "coeff" "(" Int ")"
                 | "denom" "(" Coeff ")"           [function]
                 | "lcm" "(" Coeff "," Coeff ")"   [function]
                 | "mul" "(" Coeff "," Coeff ")"   [function]
                 | "convert" "(" Coeff ")"         [function]

  syntax Poly ::= ".Poly"
                | "cons" "(" Coeff "," Poly ")"
                | "dupMulGround" "(" Poly "," Coeff ")" [function]
                | "dupStrip" "(" Poly ")"               [function]

  syntax DPoly ::= "leaf" "(" Poly ")"
                 | ".DPoly"
                 | "dcons" "(" DPoly "," DPoly ")"
                 | "dmpMulGround" "(" DPoly "," Coeff ")" [function]
                 | "recStrip" "(" DPoly ")"               [function]

  syntax Result ::= "pair" "(" Coeff "," Poly ")"
                  | "dpair" "(" Coeff "," DPoly ")"

  syntax Coeff ::= "dupCommon" "(" Poly "," Coeff ")"  [function]
                 | "dmpCommon" "(" DPoly "," Coeff ")" [function]

  syntax Result ::= "dupClearDenoms" "(" Poly ")"  [function]
                  | "dmpClearDenoms" "(" DPoly ")" [function]

  syntax Bool ::= "isZero" "(" Coeff ")" [function]
                | "polyZero" "(" Poly ")" [function]
                | "dpolyZero" "(" DPoly ")" [function]
                | "canonical" "(" Poly ")" [function]
                | "dcanonical" "(" DPoly ")" [function]
endmodule

module MINI-DENSE-POLYS
  imports MINI-DENSE-POLYS-SYNTAX
  imports BOOL
  imports INT

  configuration <k> $PGM:Result </k>

  // Coefficient facts needed for the reported issue shape.
  rule isZero(zero) => true
  rule isZero(one) => false
  rule isZero(latentZero) => false
  rule isZero(denLatentZero) => false
  rule isZero(coeff(I:Int)) => I ==Int 0

  rule denom(zero) => one
  rule denom(one) => one
  rule denom(coeff(I:Int)) => one
  rule denom(latentZero) => denLatentZero
  rule denom(denLatentZero) => one

  rule lcm(one, C:Coeff) => C
  rule lcm(C:Coeff, one) => C
  rule lcm(C:Coeff, C:Coeff) => C

  rule mul(zero, C:Coeff) => zero
  rule mul(C:Coeff, zero) => zero
  rule mul(one, C:Coeff) => C
  rule mul(C:Coeff, one) => C
  // Models the EX case where clearing denominators exposes exact zero.
  rule mul(latentZero, denLatentZero) => zero
  rule mul(denLatentZero, latentZero) => zero

  // Univariate denominator accumulation and multiplication.
  rule dupCommon(.Poly, C:Coeff) => C
  rule dupCommon(cons(CF:Coeff, F:Poly), C:Coeff)
    => dupCommon(F, lcm(C, denom(CF)))

  rule dupMulGround(.Poly, C:Coeff) => .Poly
  rule dupMulGround(F:Poly, C:Coeff) => .Poly
    requires isZero(C)
  rule dupMulGround(cons(CF:Coeff, F:Poly), C:Coeff)
    => cons(mul(CF, C), dupMulGround(F, C))
    requires notBool isZero(C)

  // Canonicalization: remove leading zero coefficients only.
  rule dupStrip(.Poly) => .Poly
  rule dupStrip(cons(CF:Coeff, F:Poly)) => dupStrip(F)
    requires isZero(CF)
  rule dupStrip(cons(CF:Coeff, F:Poly)) => cons(CF, F)
    requires notBool isZero(CF)

  rule polyZero(F:Poly) => dupStrip(F) ==K .Poly
  rule canonical(.Poly) => true
  rule canonical(cons(CF:Coeff, F:Poly)) => notBool isZero(CF)

  rule dupClearDenoms(F:Poly)
    => pair(dupCommon(F, one), dupStrip(dupMulGround(F, dupCommon(F, one))))

  // Recursive dense polynomial model. leaf(P) is the ground univariate level;
  // dcons(head, tail) is a recursive coefficient list.
  rule dmpCommon(leaf(F:Poly), C:Coeff) => dupCommon(F, C)
  rule dmpCommon(.DPoly, C:Coeff) => C
  rule dmpCommon(dcons(H:DPoly, T:DPoly), C:Coeff)
    => dmpCommon(T, dmpCommon(H, C))

  rule dmpMulGround(leaf(F:Poly), C:Coeff) => leaf(dupMulGround(F, C))
  rule dmpMulGround(.DPoly, C:Coeff) => .DPoly
  rule dmpMulGround(dcons(H:DPoly, T:DPoly), C:Coeff)
    => dcons(dmpMulGround(H, C), dmpMulGround(T, C))

  rule dpolyZero(leaf(F:Poly)) => polyZero(F)
  rule dpolyZero(.DPoly) => true
  rule dpolyZero(dcons(H:DPoly, .DPoly)) => dpolyZero(H)
  rule dpolyZero(dcons(H:DPoly, T:DPoly)) => false
    requires notBool T ==K .DPoly

  rule recStrip(leaf(F:Poly)) => leaf(dupStrip(F))
  rule recStrip(.DPoly) => .DPoly
  rule recStrip(dcons(H:DPoly, T:DPoly)) => recStrip(T)
    requires dpolyZero(recStrip(H))
  rule recStrip(dcons(H:DPoly, T:DPoly)) => dcons(recStrip(H), recStrip(T))
    requires notBool dpolyZero(recStrip(H))

  rule dcanonical(leaf(F:Poly)) => canonical(F)
  rule dcanonical(.DPoly) => true
  rule dcanonical(dcons(H:DPoly, T:DPoly))
    => (notBool dpolyZero(H)) andBool dcanonical(H) andBool dcanonical(T)

  rule dmpClearDenoms(F:DPoly)
    => dpair(dmpCommon(F, one), recStrip(dmpMulGround(F, dmpCommon(F, one))))
endmodule
