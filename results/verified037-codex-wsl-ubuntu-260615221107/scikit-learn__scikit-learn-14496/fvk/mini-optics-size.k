module MINI-OPTICS-SIZE-SYNTAX
  imports INT-SYNTAX

  syntax FVal ::= "two"
                | "scaled" "(" Int "," Int ")"       [function]
                | "maxF" "(" FVal "," FVal ")"        [function]

  syntax Int ::= "roundPy" "(" FVal ")"               [function]

  syntax SizeExp ::= "normalizeFractional" "(" FVal ")"
                   | "passAbsolute" "(" Int ")"

  syntax KResult ::= Int
endmodule

module MINI-OPTICS-SIZE
  imports MINI-OPTICS-SIZE-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:SizeExp </k>

  // Abstract model of: int(round(max(2, size * n_samples))).
  // FVal represents Python's finite floating value after multiplication.
  // roundPy is sorted as Int to capture the postcondition needed here:
  // NearestNeighbors and Xi thresholds receive an integer count.
  rule <k> normalizeFractional(V:FVal) => roundPy(maxF(two, V)) ... </k>

  // Absolute integer counts are outside the reported fractional branch.
  rule <k> passAbsolute(I:Int) => I ... </k>
endmodule
