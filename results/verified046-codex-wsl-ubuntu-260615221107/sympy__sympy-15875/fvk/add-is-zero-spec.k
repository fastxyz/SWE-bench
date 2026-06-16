requires "mini-add-is-zero.k"

module ADD-IS-ZERO-SPEC
  imports MINI-ADD-IS-ZERO

  // SPEC-PROVENANCE:
  // - from_prompt: "is_zero should return None if it cannot decide, but should never give the wrong answer"
  //   => an undecidable multi-imaginary cancellation must not return F.
  // - from_prompt: "-2*I + (1 + I)**2" has e.is_zero == False while simplify(e).is_zero == True
  //   => the reported class is two definitely imaginary terms, zero real part, no same-sign certificate.
  claim <k> addZero(true, false, T, false, 2, U, NoSS) => U </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: "(a + I).is_zero is False" with a zero symbol
  //   => one definitely imaginary nonzero term and zero real part is nonzero.
  // - from_docs: "0 is not considered to be an imaginary number"
  //   => is_imaginary=True implies the single imaginary term is nonzero.
  claim <k> addZero(true, false, T, false, 1, U, NoSS) => F </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_assumption_sign_rules: all nonnegative coefficients with one positive,
  //   or all nonpositive coefficients with one negative, cannot sum to zero.
  claim <k> addZero(true, false, T, false, N:Int, U, SSPos) => F </k>
    requires N >Int 1
    [all-path]

  claim <k> addZero(true, false, T, false, N:Int, U, SSNeg) => F </k>
    requires N >Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_complex_arithmetic: a nonzero real part cannot be canceled by purely
  //   imaginary-or-zero terms.
  claim <k> addZero(true, false, F, HAS_MAYBE:Bool, N:Int, IM_ZERO:Truth, SIGN:SignCert) => F </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_complex_arithmetic: zero real part plus imaginary coefficients known
  //   to sum to zero is exactly zero.
  claim <k> addZero(true, false, T, false, N:Int, T, SIGN:SignCert) => T </k>
    requires N >Int 0
    [all-path]
endmodule
