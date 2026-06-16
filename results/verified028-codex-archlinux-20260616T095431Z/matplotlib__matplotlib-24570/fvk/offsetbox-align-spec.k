requires "mini-python-offsetbox.k"

module OFFSETBOX-ALIGN-SPEC
  imports MINI-PYTHON-OFFSETBOX
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "`align` in `HPacker` is reversed" and the reproduction
  //   expects align="bottom" to align child bottoms.
  // - from_docs_or_code: _get_aligned_offsets returns "bottom offsets".
  // - from_code: HPacker passes (height, ydescent) pairs into this helper.
  claim
    <k> lowerEdge(offset(H:Int, D:Int, T:Int, bottomA), D) => 0 ... </k>
    requires (0 <=Int D) andBool (D <=Int H) andBool (H <=Int T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: top and bottom in HPacker must not be reversed.
  // - from_docs_or_code: a top-aligned child has upper edge at container
  //   height T.
  // - from_code: HPacker passes (height, ydescent) pairs into this helper.
  claim
    <k> upperEdge(offset(H:Int, D:Int, T:Int, topA), D, H) => T ... </k>
    requires (0 <=Int D) andBool (D <=Int H) andBool (H <=Int T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: VPacker align='left' works as expected.
  // - from_docs_or_code: the same helper works for vertical layout by treating
  //   width/xdescent as the size/descent pair.
  claim
    <k> lowerEdge(offset(W:Int, D:Int, T:Int, leftA), D) => 0 ... </k>
    requires (0 <=Int D) andBool (D <=Int W) andBool (W <=Int T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: VPacker align='right' works as expected.
  // - from_docs_or_code: the far edge of a right-aligned child is the
  //   container width T.
  claim
    <k> upperEdge(offset(W:Int, D:Int, T:Int, rightA), D, W) => T ... </k>
    requires (0 <=Int D) andBool (D <=Int W) andBool (W <=Int T)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_frame_condition: baseline branch was not part of the reported bug
  //   and remains unchanged.
  claim
    <k> offset(H:Int, D:Int, T:Int, baselineA) => 0 ... </k>
    [all-path]
endmodule
