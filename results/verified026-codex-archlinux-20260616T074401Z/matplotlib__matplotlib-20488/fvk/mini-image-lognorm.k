requires "domains.md"

module MINI-IMAGE-LOGNORM
  imports INT
  imports BOOL

  // Minimal fragment for the audited branch in image.py.
  // Int values model the ordered finite scalar sign relation only; magnitudes
  // outside the sign comparison are intentionally abstracted away.
  syntax Int ::= adjustLogVmin(Bool, Int, Int) [function]
  syntax Int ::= maxScalar(Int, Int) [function]

  rule maxScalar(A, B) => A requires A >=Int B
  rule maxScalar(A, B) => B requires A <Int B

  rule adjustLogVmin(true, S, EPS) => maxScalar(S, EPS)
    requires S <=Int 0
  rule adjustLogVmin(true, S, EPS) => S
    requires S >Int 0
  rule adjustLogVmin(false, S, EPS) => S
endmodule
