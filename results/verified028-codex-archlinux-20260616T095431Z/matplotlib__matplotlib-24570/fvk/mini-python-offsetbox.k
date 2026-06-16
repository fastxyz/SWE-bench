module MINI-PYTHON-OFFSETBOX-SYNTAX
  imports INT-SYNTAX

  syntax Align ::= "baselineA" | "leftA" | "bottomA"
                 | "rightA" | "topA" | "centerA"

  syntax IExp ::= Int
                | "offset" "(" IExp "," IExp "," IExp "," Align ")"
                  [strict(1, 2, 3)]
                | "lowerEdge" "(" IExp "," IExp ")" [strict(1, 2)]
                | "upperEdge" "(" IExp "," IExp "," IExp ")"
                  [strict(1, 2, 3)]

  syntax KResult ::= Int
endmodule

module MINI-PYTHON-OFFSETBOX
  imports MINI-PYTHON-OFFSETBOX-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:IExp </k>

  // Property-complete abstraction of _get_aligned_offsets' per-child branch
  // table after the V1 fix.
  rule <k> offset(H:Int, D:Int, T:Int, baselineA) => 0 ... </k>
  rule <k> offset(H:Int, D:Int, T:Int, leftA) => D ... </k>
  rule <k> offset(H:Int, D:Int, T:Int, bottomA) => D ... </k>
  rule <k> offset(H:Int, D:Int, T:Int, rightA) => T -Int H +Int D ... </k>
  rule <k> offset(H:Int, D:Int, T:Int, topA) => T -Int H +Int D ... </k>
  rule <k> offset(H:Int, D:Int, T:Int, centerA) => (T -Int H) /Int 2 +Int D ... </k>

  rule <k> lowerEdge(O:Int, D:Int) => O -Int D ... </k>
  rule <k> upperEdge(O:Int, D:Int, H:Int) => O -Int D +Int H ... </k>
endmodule
