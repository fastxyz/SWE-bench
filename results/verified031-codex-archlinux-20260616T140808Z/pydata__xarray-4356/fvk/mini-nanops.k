module MINI-NANOPS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Decision ::= "keep" | "null"
  syntax Exp ::= maybeNull(Int, Int, Int)

  syntax KResult ::= Decision
endmodule

module MINI-NANOPS
  imports MINI-NANOPS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // maybeNull(total, nulls, min_count) models the decision made by
  // _maybe_null_out for one output position after the reduction result exists.
  rule <k> maybeNull(TOTAL:Int, NULLS:Int, MIN:Int) => null ... </k>
    requires TOTAL -Int NULLS -Int MIN <Int 0

  rule <k> maybeNull(TOTAL:Int, NULLS:Int, MIN:Int) => keep ... </k>
    requires TOTAL -Int NULLS -Int MIN >=Int 0
endmodule
