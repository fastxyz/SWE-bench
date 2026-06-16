// Constructed, not machine-checked.
// Minimal K-style semantics for the attrs axis of xarray quantile.

module MINI-XARRAY-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX
  imports ID-SYNTAX

  syntax Keep ::= "true" | "false" | "default"
  syntax Q ::= "q" "(" Id ")"
  syntax Dim ::= "dim" "(" Id ")"
  syntax Interp ::= "interp" "(" Id ")"
  syntax Dims ::= "dims" "(" Id ")"
                | "quantileDims" "(" Dims "," Q "," Dim ")"
  syntax Data ::= "data" "(" Id ")"
                | "quantileData" "(" Data "," Q "," Dim "," Interp ")"
  syntax Variable ::= "var" "(" Dims "," Data "," Map ")"
  syntax Dataset ::= "dataset" "(" Map "," Map "," Map ")"
  syntax DataArray ::= "dataarray" "(" Variable "," Map ")"

  syntax KItem ::= "variableQuantile" "(" Variable "," Q "," Dim "," Interp "," Keep ")"
                 | "datasetQuantile" "(" Dataset "," Q "," Dim "," Interp "," Keep ")"
                 | "dataArrayQuantile" "(" DataArray "," Q "," Dim "," Interp "," Keep ")"

  syntax Bool ::= "resolveKeep" "(" Keep "," Bool ")" [function]
  syntax Map ::= "keptAttrs" "(" Map "," Bool ")" [function]
endmodule

module MINI-XARRAY
  imports MINI-XARRAY-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <globalKeep> false </globalKeep>

  rule resolveKeep(true, _) => true
  rule resolveKeep(false, _) => false
  rule resolveKeep(default, G:Bool) => G

  rule keptAttrs(ATTRS:Map, true) => ATTRS
  rule keptAttrs(_, false) => .Map

  // Variable.quantile: numeric value/dim computation is framed as
  // quantileData/quantileDims; attrs are the observable under verification.
  rule
    <k> variableQuantile(var(DIMS, DATA, ATTRS), Q, DIM, INTERP, KEEP)
      => var(quantileDims(DIMS, Q, DIM),
             quantileData(DATA, Q, DIM, INTERP),
             keptAttrs(ATTRS, resolveKeep(KEEP, G))) ... </k>
    <globalKeep> G </globalKeep>

  // Dataset.quantile over a one-data-variable shape sufficient to model the
  // DataArray temporary dataset route. VARS is represented as a map containing
  // the data variable key "x". COORDS/index handling is framed.
  rule
    <k> datasetQuantile(dataset("x" |-> var(DIMS, DATA, ATTRS), COORDS, DATTRS),
                        Q, DIM, INTERP, KEEP)
      => dataset("x" |-> var(quantileDims(DIMS, Q, DIM),
                             quantileData(DATA, Q, DIM, INTERP),
                             keptAttrs(ATTRS, resolveKeep(KEEP, G))),
                 COORDS,
                 keptAttrs(DATTRS, resolveKeep(KEEP, G))) ... </k>
    <globalKeep> G </globalKeep>

  // DataArray.quantile delegates through a temporary one-variable dataset and
  // then extracts the same data variable back into a DataArray.
  rule
    <k> dataArrayQuantile(dataarray(var(DIMS, DATA, ATTRS), COORDS),
                          Q, DIM, INTERP, KEEP)
      => dataarray(var(quantileDims(DIMS, Q, DIM),
                       quantileData(DATA, Q, DIM, INTERP),
                       keptAttrs(ATTRS, resolveKeep(KEEP, G))),
                   COORDS) ... </k>
    <globalKeep> G </globalKeep>
endmodule
