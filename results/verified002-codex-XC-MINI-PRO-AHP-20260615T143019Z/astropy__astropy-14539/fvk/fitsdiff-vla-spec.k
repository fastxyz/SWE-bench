requires "mini-fitsdiff.k"

module FITSDIFF-VLA-SPEC
  imports MINI-FITSDIFF

  // SPEC-PROVENANCE:
  // - E-004: public hint says only P was handled; Q must join the VLA path.
  claim <k> isVLA(Q) => true ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: existing P VLA behavior must remain VLA-dispatched.
  claim <k> isVLA(P) => true ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - E-005 and non-VLA frame condition: other formats do not enter VLA path.
  claim <k> isVLA(OTHER) => false ... </k> [all-path]

  // SPEC-PROVENANCE:
  // - VLA row shape is part of row equality.
  claim
    <k> vlaValuesDiffer(row(false, K:Kind, FC:Bool, NC:Bool, EC:Bool)) => true ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-006/E-007: floating data uses FITSDiff floating helper semantics.
  claim
    <k> vlaValuesDiffer(row(true, FLOAT, true, NC:Bool, EC:Bool)) => false ... </k>
    [all-path]

  claim
    <k> vlaValuesDiffer(row(true, FLOAT, false, NC:Bool, EC:Bool)) => true ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Numeric non-floating VLA rows preserve tolerance-aware comparison.
  claim
    <k> vlaValuesDiffer(row(true, NUMBER, FC:Bool, true, EC:Bool)) => false ... </k>
    [all-path]

  claim
    <k> vlaValuesDiffer(row(true, NUMBER, FC:Bool, false, EC:Bool)) => true ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Non-numeric VLA rows use exact equality.
  claim
    <k> vlaValuesDiffer(row(true, NONNUM, FC:Bool, NC:Bool, true)) => false ... </k>
    [all-path]

  claim
    <k> vlaValuesDiffer(row(true, NONNUM, FC:Bool, NC:Bool, false)) => true ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-003: identical QD rows contribute zero differences.
  claim
    <k> rowDiffCount(Q,
          row(true, FLOAT, true, true, true)
        ; row(true, FLOAT, true, true, true)
        ; .Rows)
        => 0
        ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Real row differences must be surfaced.
  claim
    <k> rowDiffCount(Q, row(false, FLOAT, true, true, true) ; .Rows) => 1 ... </k>
    [all-path]
endmodule
