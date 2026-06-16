requires "mini-sympy-fu.k"

module MINI-SYMPY-FU-SPEC
  imports MINI-SYMPY-FU

  // SPEC-PROVENANCE:
  // - from_prompt: simplify(cos(x)**I) raised Invalid comparison of complex I.
  // - obligation: non-integer exponents return before ordered comparison.
  claim <k> tr56(nonInteger, MAX:Int, MODE:PowMode) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: perfect_power requires a concrete integer via as_int.
  // - obligation: symbolic integer exponents in pow=True mode are unchanged.
  claim <k> tr56(symbolicInteger, MAX:Int, powTrue) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: negative powers are unchanged.
  claim <k> tr56(concrete(-2), 4, powFalse) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: exponent greater than max is unchanged.
  claim <k> tr56(concrete(10), 4, powFalse) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: exponent 2 rewrites to h(g(arg)**2).
  claim <k> tr56(concrete(2), 4, powFalse) => rewrite2 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: exponent 4 rewrites to h(g(arg)**2)**2.
  claim <k> tr56(concrete(4), 4, powFalse) => rewriteHalf(2) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: sin(x)**6 rewrites when pow=False and max=6.
  claim <k> tr56(concrete(6), 6, powFalse) => rewriteHalf(3) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: odd powers are unchanged.
  claim <k> tr56(concrete(3), 4, powFalse) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: pow=True leaves exponent 6 unchanged.
  claim <k> tr56(concrete(6), 10, powTrue) => unchanged </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: pow=True rewrites exponent 8.
  claim <k> tr56(concrete(8), 10, powTrue) => rewriteHalf(4) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: pow=True means powers of two, not all perfect powers.
  claim <k> tr56(concrete(9), 10, powTrue) => unchanged </k>
    [all-path]
endmodule
