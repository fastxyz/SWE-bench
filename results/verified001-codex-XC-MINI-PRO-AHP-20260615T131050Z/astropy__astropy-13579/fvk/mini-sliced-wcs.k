// Abstract mini-K semantics for the SlicedLowLevelWCS data flow.
// Constructed, not machine-checked. This intentionally models only the wrapper
// reconstruction logic; the wrapped WCS transforms are abstract functions.

module MINI-SLICED-WCS-SYNTAX
  imports BOOL-SYNTAX

  syntax WCS
  syntax Slices
  syntax AxisSet
  syntax Vec

  syntax Exp ::= "worldToPixelValues" "(" WCS "," Slices "," AxisSet "," AxisSet "," Vec ")"
               | "droppedWorldValues" "(" WCS "," Slices ")"

  syntax KResult ::= Vec
endmodule

module MINI-SLICED-WCS
  imports MINI-SLICED-WCS-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Exp </k>

  syntax Vec ::= "p2w" "(" WCS "," Vec ")" [function]
               | "w2p" "(" WCS "," Vec ")" [function]
               | "expandPixels" "(" Slices "," Vec ")" [function]
               | "expandPixelsAtSlicedZero" "(" Slices ")" [function]
               | "selectKeptWorlds" "(" Vec "," AxisSet ")" [function]
               | "selectKeptPixels" "(" Vec "," AxisSet ")" [function]
               | "mergeKeptAndDroppedWorlds" "(" AxisSet "," Vec "," Vec ")" [function]
               | "adjustForSliceStarts" "(" Vec "," Slices ")" [function]

  syntax Bool ::= "validSlicedWCS" "(" WCS "," Slices "," AxisSet "," AxisSet ")" [function]
                | "droppedWorldsIndependent" "(" WCS "," Slices "," AxisSet "," AxisSet "," Vec ")" [function]
                | "wrappedInverseOnSlice" "(" WCS "," Slices "," Vec ")" [function]

  rule <k> droppedWorldValues(W:WCS, S:Slices)
        => p2w(W, expandPixelsAtSlicedZero(S)) ... </k>

  rule <k> worldToPixelValues(W:WCS, S:Slices, PK:AxisSet, WK:AxisSet, WIN:Vec)
        => selectKeptPixels(
             adjustForSliceStarts(
               w2p(W, mergeKeptAndDroppedWorlds(
                 WK,
                 WIN,
                 p2w(W, expandPixelsAtSlicedZero(S)))),
               S),
             PK)
        ... </k>
endmodule
