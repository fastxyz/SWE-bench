requires "mini-sympy-surds.k"

module SQRTDENEST-SPEC
  imports MINI-SYMPY-SURDS

  // Claim C1.
  // SPEC-PROVENANCE:
  // - from_problem: "4+I ... leads to an empty surds list" => _sqrt_match
  //   should not call split_surds for non-positive rational squares.
  // - from_problem: "If an expression cannot be denested it should be returned
  //   unchanged" => no match is the expected helper result.
  claim
    <k> sqrtMatch(add2(four, iUnit)) => noMatch ... </k>
    [all-path]

  // Claim C2.
  // SPEC-PROVENANCE:
  // - from_problem: split_surds called _split_gcd with no collected surds.
  // - from_code: _split_gcd requires a non-empty argument tuple.
  claim
    <k> splitSurds(add2(four, iUnit))
      => split(one, zero, add2(four, iUnit)) ... </k>
    [all-path]

  // Claim C3.
  // SPEC-PROVENANCE:
  // - from_problem: rad_rationalize is documented and should not fail for
  //   4+I.
  // - from_default_domain: no square-root component means no-op is the
  //   minimal best-effort simplification result.
  claim
    <k> radRat(one, add2(four, iUnit))
      => pair(one, add2(four, iUnit)) ... </k>
    [all-path]

  // Claim C4.
  // SPEC-PROVENANCE:
  // - from_problem: rad_rationalize(1, 1+cbrt(2)) used to recurse forever.
  // - from_default_domain: cube roots are unsupported by this square-root
  //   rationalizer.
  claim
    <k> radRat(one, add2(one, cbrt2))
      => pair(one, add2(one, cbrt2)) ... </k>
    [all-path]

  // Claim C5.
  // SPEC-PROVENANCE:
  // - from_problem: rad_rationalize(1, sqrt(2)+I) returns (sqrt(2)-I, 3).
  // - frame_condition: V1 no-surd guard must not disable supported sqrt terms.
  claim
    <k> radRat(one, add2(sqrt2, iUnit))
      => pair(sqrt2MinusI, three) ... </k>
    [all-path]

  // Claim C6.
  // SPEC-PROVENANCE:
  // - from_docstring: split_surds documented regular-surd example returns the
  //   grouped tuple.
  // - frame_condition: regular positive square-root sums remain supported.
  claim
    <k> splitSurds(docDen) => split(three, docA, docB) ... </k>
    [all-path]
endmodule
