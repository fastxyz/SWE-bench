requires "mini-sliced-wcs.k"

module SLICED-WCS-SPEC
  imports MINI-SLICED-WCS
  imports BOOL
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E2: the sliced inverse must return the same kept pixel components as the
  //   corresponding full WCS inverse.
  // - E3: dropped world axes must be reconstructed from the fixed slice pixel,
  //   not from a placeholder.
  // - from_code: worldToPixelValues models the current wrapper data flow:
  //   kept world values from the caller, dropped values from p2w at sliced zero,
  //   wrapped inverse, slice-start adjustment, and kept-pixel selection.
  claim <k>
          worldToPixelValues(
            W:WCS, S:Slices, PK:AxisSet, WK:AxisSet,
            selectKeptWorlds(p2w(W, expandPixels(S, P:Vec)), WK))
        => P
        ... </k>
    requires validSlicedWCS(W, S, PK, WK)
     andBool droppedWorldsIndependent(W, S, PK, WK, P)
     andBool wrappedInverseOnSlice(W, S, P)
     andBool { mergeKeptAndDroppedWorlds(
                 WK,
                 selectKeptWorlds(p2w(W, expandPixels(S, P)), WK),
                 p2w(W, expandPixelsAtSlicedZero(S)))
               #Equals p2w(W, expandPixels(S, P)) }
     andBool { w2p(W, p2w(W, expandPixels(S, P)))
               #Equals expandPixels(S, P) }
     andBool { selectKeptPixels(
                 adjustForSliceStarts(expandPixels(S, P), S), PK)
               #Equals P }
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E7: dropped-world metadata and inverse reconstruction must share the
  //   fixed-slice world coordinate source.
  claim <k> droppedWorldValues(W:WCS, S:Slices)
        => p2w(W, expandPixelsAtSlicedZero(S)) ... </k>
    requires validSlicedWCS(W, S, PK:AxisSet, WK:AxisSet)
    [all-path]
endmodule
