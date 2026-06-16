module MINI-SYMPY-SETS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Expr ::= "IssueExpr" | "IssueImag" | "Id" | "OneOverN" | "Zero"
  syntax Set ::= "Integers" | "EmptySet" | "IssueRoots" | "IssueResult"
               | "NonZeroIntegers" | "IssueRootsZero"
               | Set "/\\" Set [left]
               | Set "\\" Set [left]
               | "imageSet" "(" Expr "," Set ")"
  syntax Image ::= "Image" "(" Expr "," Set ")"
  syntax Set ::= "intersectReals" "(" Image ")" [function]
  syntax Expr ::= "realPart" "(" Expr ")" [function]
                | "imagPart" "(" Expr ")" [function]
  syntax Set ::= "zeroSet" "(" Expr ")" [function]
               | "singularSet" "(" Expr ")" [function]
  syntax Bool ::= "contains" "(" Int "," Set ")" [function]
  syntax KResult ::= Set | Expr | Bool
endmodule

module MINI-SYMPY-SETS
  imports MINI-SYMPY-SETS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // SPEC-PROVENANCE:
  // - from_prompt: reported expression n + I*(n - 1)*(n + 1).
  // - from_default_domain: real intersection keeps im(n) == 0 parameters.
  // - from_code: V1 computes realPart, imagPart, zero roots, denominator roots.
  rule realPart(IssueExpr) => Id
  rule imagPart(IssueExpr) => IssueImag
  rule zeroSet(IssueImag) => IssueRoots
  rule singularSet(IssueExpr) => EmptySet

  // IssueRoots models FiniteSet(-1, 1); IssueResult models the same set after
  // applying the identity real part.
  rule Integers /\ IssueRoots => IssueRoots
  rule IssueRoots \ EmptySet => IssueRoots
  rule imageSet(Id, IssueRoots) => IssueResult

  rule contains(2, IssueResult) => false
  rule contains(-1, IssueResult) => true
  rule contains(1, IssueResult) => true

  // Denominator frame for imageset(Lambda(n, 1/n), Integers).
  rule realPart(OneOverN) => OneOverN
  rule imagPart(OneOverN) => Zero
  rule zeroSet(Zero) => Integers
  rule singularSet(OneOverN) => IssueRootsZero
  rule Integers /\ Integers => Integers
  rule Integers \ IssueRootsZero => NonZeroIntegers

  rule intersectReals(Image(F:Expr, B:Set))
    => imageSet(realPart(F), (B /\ zeroSet(imagPart(F))) \ singularSet(F))
endmodule
