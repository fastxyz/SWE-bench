requires "mini-java-shapefield.k"

module SHAPE-FIELD-SPEC
  imports MINI-JAVA-SHAPEFIELD
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - E2: degenerate triangle simplification is in scope.
  // - E4: when A-B collapses, metadata must come from a non-collapsed segment.
  // - E5: CONTAINS line queries consume the resulting ab flag.
  claim [RESOLVE-AEQB-LINE]:
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, BC, CX, CY, ?BCOut:Bool, AX, AY, ?CAOut:Bool, LINE) </tri>
    requires AX ==Int BX andBool AY ==Int BY
     andBool notBool (AX ==Int CX andBool AY ==Int CY)
    [all-path]

  // SPEC-PROVENANCE:
  // - Intent 4: all equal decoded vertices simplify to POINT.
  claim [RESOLVE-POINT]:
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, POINT) </tri>
    requires AX ==Int BX andBool AY ==Int BY
     andBool AX ==Int CX andBool AY ==Int CY
    [all-path]

  // SPEC-PROVENANCE:
  // - Intent 3: A-C collapse already represents line A-B-A using ab.
  claim [RESOLVE-AEQC-LINE]:
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, ?BCOut:Bool, CX, CY, ?CAOut:Bool, LINE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool AX ==Int CX andBool AY ==Int CY
    [all-path]

  // SPEC-PROVENANCE:
  // - Intent 3: B-C collapse canonicalizes to line A-B-A using ab.
  claim [RESOLVE-BEQC-LINE]:
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, ?BCOut:Bool, AX, AY, ?CAOut:Bool, LINE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool notBool (AX ==Int CX andBool AY ==Int CY)
     andBool BX ==Int CX andBool BY ==Int CY
    [all-path]

  // SPEC-PROVENANCE:
  // - Intent 4: pairwise distinct decoded vertices remain a TRIANGLE.
  claim [RESOLVE-TRIANGLE]:
    <k> resolveTriangleType => .K </k>
    <tri> DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, T)
       => DT(AX, AY, AB, BX, BY, BC, CX, CY, CA, TRIANGLE) </tri>
    requires notBool (AX ==Int BX andBool AY ==Int BY)
     andBool notBool (AX ==Int CX andBool AY ==Int CY)
     andBool notBool (BX ==Int CX andBool BY ==Int CY)
    [all-path]
endmodule
