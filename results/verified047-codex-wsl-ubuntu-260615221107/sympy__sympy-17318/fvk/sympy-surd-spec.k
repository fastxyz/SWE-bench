requires "mini-sympy-surd.k"

module SYMPY-SURD-SPEC
  imports MINI-SYMPY-SURD

  // SPEC-PROVENANCE:
  // - I1/I2: non-denestable flat complex bases must return unchanged.
  // - I3: the pre-fix bug was reaching splitSurds with 4 + I.
  claim <k> sqrtMatch(ISSUE-BASE-4I) => NO-MATCH </k>

  // SPEC-PROVENANCE:
  // - I3/I4: no square-root surds means splitSurds returns a neutral split.
  claim <k> splitSurds(ISSUE-DEN-4I) => SPLIT(1, ZERO, ISSUE-DEN-4I) </k>

  // SPEC-PROVENANCE:
  // - I4: cube roots are outside this square-root rationalizer's scope.
  claim <k> splitSurds(CBRT-DEN) => SPLIT(1, ZERO, CBRT-DEN) </k>

  // SPEC-PROVENANCE:
  // - I3: empty gcd helper input must be safe.
  claim <k> splitGcd(.List) => GCDSPLIT(1, .List, .List) </k>

  // SPEC-PROVENANCE:
  // - I4: no-surd additive denominators return unchanged.
  claim <k> radRationalize(ONE, ISSUE-DEN-4I) => PAIR(ONE, ISSUE-DEN-4I) </k>

  // SPEC-PROVENANCE:
  // - I4: higher-root additive denominators return unchanged.
  claim <k> radRationalize(ONE, CBRT-DEN) => PAIR(ONE, CBRT-DEN) </k>

  // SPEC-PROVENANCE:
  // - I5: valid sqrt(2) + I rationalization is preserved.
  claim <k> radRationalize(ONE, SQRT2-PLUS-I) => PAIR(SQRT2-MINUS-I, THREE) </k>
endmodule
