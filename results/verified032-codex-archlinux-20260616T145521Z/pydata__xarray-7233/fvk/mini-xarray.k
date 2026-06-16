module MINI-XARRAY-SYNTAX
  imports BOOL
  imports SET
  imports STRING

  syntax XObj ::= "ds" "(" Set "," Set ")"                 [symbol(ds)]
  syntax KItem ::= "constructV2" "(" XObj ")"               [symbol(constructV2)]
                 | "constructV1" "(" XObj "," Set ")"       [symbol(constructV1)]
                 | "reshapeAll" "(" XObj ")"                [symbol(reshapeAll)]
                 | "setCoords" "(" XObj "," Set ")"         [symbol(setCoords)]

  syntax Bool ::= Set "subsetSet" Set                      [function, symbol(subsetSet)]
  syntax Set ::= Set "intersectSet" Set                     [function, symbol(intersectSet)]
endmodule

module MINI-XARRAY
  imports MINI-XARRAY-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstract membership helpers for finite sets of variable names.
  rule .Set subsetSet _ => true
  rule (SetItem(N) REST) subsetSet S
    => (N in S) andBool (REST subsetSet S)

  rule .Set intersectSet _ => .Set
  rule (SetItem(N) REST) intersectSet S
    => SetItem(N) (REST intersectSet S)
    requires N in S
  rule (SetItem(N) REST) intersectSet S
    => REST intersectSet S
    requires notBool (N in S)

  // The reshape loop changes variable payloads and dimensions, but preserves
  // variable names. It does not by itself establish the original coordinate set.
  rule <k> reshapeAll(ds(VARS, _COORDS)) => ds(VARS, .Set) ... </k>

  // Dataset.set_coords requires all requested names to be variables, then adds
  // those names to the coordinate-name set.
  rule <k> setCoords(ds(VARS, RCOORDS), NAMES)
        => ds(VARS, RCOORDS |Set NAMES) ... </k>
    requires NAMES subsetSet VARS

  // V2 / audited implementation: pass all original coordinate names.
  rule <k> constructV2(ds(VARS, COORDS))
        => setCoords(reshapeAll(ds(VARS, COORDS)), COORDS) ... </k>
    requires COORDS subsetSet VARS

  // Pre-fix implementation: pass only coordinates whose names are window keys.
  rule <k> constructV1(ds(VARS, COORDS), WINDOWNAMES)
        => setCoords(reshapeAll(ds(VARS, COORDS)), COORDS intersectSet WINDOWNAMES) ... </k>
    requires COORDS subsetSet VARS
endmodule
