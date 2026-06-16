requires "mini-sympy-point.k"

module POINT-IMAGINARY-VALIDATION-SPEC
  imports MINI-SYMPY-POINT

  // SPEC-PROVENANCE:
  // - E-001/E-002: real numeric coordinates under evaluate(False) must pass.
  // - E-005: the old evaluation flag must be restored.
  // Claim: POINT-VALIDATEEVAL-PASS
  claim
    <k> validateEval(CS:Coords, OLD:Bool) => .K </k>
    <eval> true => OLD </eval>
    <out> ok => ok </out>
    requires anyBad(CS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003: numeric coordinates with nonzero evaluated imaginary parts raise.
  // - E-005: the old evaluation flag must be restored even on error.
  // Claim: POINT-VALIDATEEVAL-ERROR
  claim
    <k> validateEval(CS:Coords, OLD:Bool) => .K </k>
    <eval> true => OLD </eval>
    <out> ok => imaginaryError </out>
    requires anyBad(CS) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001: the public top-level path under old evaluate(False) passes for
  //   real integer coordinates.
  // - E-002: residual-zero numeric coordinates are classified using evaluated
  //   probe semantics.
  // Claim: POINT-VALIDATE-PASS
  claim
    <k> validate(CS:Coords) => .K </k>
    <eval> OLD:Bool => OLD </eval>
    <out> ok => ok </out>
    requires anyBad(CS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003: the public top-level path still rejects numeric imaginary
  //   coordinates.
  // Claim: POINT-VALIDATE-ERROR
  claim
    <k> validate(CS:Coords) => .K </k>
    <eval> OLD:Bool => OLD </eval>
    <out> ok => imaginaryError </out>
    requires anyBad(CS) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: symbolic/non-numeric coordinates are ignored by this guard.
  // Claim: POINT-SYMBOLIC-FRAME
  claim
    <k> validate(symbolicCoord ; .Coords) => .K </k>
    <eval> OLD:Bool => OLD </eval>
    <out> ok => ok </out>
    [all-path]
endmodule
