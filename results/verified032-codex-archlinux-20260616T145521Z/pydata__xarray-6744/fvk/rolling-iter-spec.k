requires "mini-python-rolling.k"

module ROLLING-ITER-VERIFICATION
  imports MINI-PYTHON-ROLLING
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "manually iterate over a DataArrayRolling object, and still
  //   be given center-justified windows" => center=True iterator bounds must
  //   match centered rolling reduction bounds.
  // - from_docs: Variable.rolling_window pads start=W /Int 2 and
  //   end=W -Int 1 -Int start for center=True.
  // - from_code: V1 computes OFFSET=(W-1)/2, STOP=I+1+OFFSET,
  //   START=STOP-W, then clips START and STOP to [0,N].
  // The following simplification states that this V1 START equals the
  // centered construction START for positive W.
  rule I:Int +Int 1 +Int ((W:Int -Int 1) /Int 2) -Int W
    => I -Int (W /Int 2)
    requires W >Int 0
    [simplification]
endmodule

module ROLLING-ITER-SPEC
  imports ROLLING-ITER-VERIFICATION

  // PO-2: center=False keeps the right-aligned bounds.
  claim
    <k> rollingBounds(N:Int, W:Int, false, I:Int)
      => pair(maxInt(I -Int (W -Int 1), 0), minInt(I +Int 1, N)) </k>
    requires N >=Int 0 andBool W >Int 0
     andBool I >=Int 0 andBool I <Int N
    [all-path]

  // PO-3 and PO-4: center=True matches Variable.rolling_window:
  // left padding W/2, right padding (W-1)/2, clipped to the data extent.
  claim
    <k> rollingBounds(N:Int, W:Int, true, I:Int)
      => pair(
           maxInt(I -Int (W /Int 2), 0),
           minInt(I +Int ((W -Int 1) /Int 2) +Int 1, N)
         )
    </k>
    requires N >=Int 0 andBool W >Int 0
     andBool I >=Int 0 andBool I <Int N
    [all-path]

  // Concrete issue witness: N=9, W=3, center=True gives edge and interior
  // windows [0:2], [0:3], ..., [7:9], so manual means align as
  // [nan, 2, 3, 4, 5, 6, 7, 8, nan] under default min_periods.
  claim <k> rollingBounds(9, 3, true, 0) => pair(0, 2) </k> [all-path]
  claim <k> rollingBounds(9, 3, true, 1) => pair(0, 3) </k> [all-path]
  claim <k> rollingBounds(9, 3, true, 8) => pair(7, 9) </k> [all-path]
endmodule
