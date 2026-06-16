requires "mini-matplotlib-widgets.k"

module SPAN-SELECTOR-SPEC
  imports MINI-MPL-WIDGETS

  // SPEC-PROVENANCE:
  // - from_prompt: "interactive SpanSelector incorrectly forces axes limits to include 0"
  //   => constructing an interactive selector must not add 0 to dataLim.
  // - from_prompt: "this is when calling ss = SpanSelector(... interactive=True)"
  //   => the construction path itself is in scope, before any user selection.
  // - from_code: V1 uses NewAxes -> AddArtist(rect) and SetupHandles -> AddArtist(line) twice.
  // CLAIM: SPAN-HORIZONTAL-INTERACTIVE
  claim
    <k> NewSpanSelector(x, true) => .K </k>
    <zeroX> false => false </zeroX>
    <zeroY> ZY:Bool => ZY </zeroY>
    <reqX> RX:Bool => RX </reqX>
    <reqY> RY:Bool => RY </reqY>
    <rects> R:Int => R +Int 1 </rects>
    <lines> L:Int => L +Int 2 </lines>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: direction is {"horizontal", "vertical"}.
  // - from_default_domain: the same UI-helper frame condition applies to the
  //   selected data axis in either direction.
  // CLAIM: SPAN-VERTICAL-INTERACTIVE
  claim
    <k> NewSpanSelector(y, true) => .K </k>
    <zeroX> ZX:Bool => ZX </zeroX>
    <zeroY> false => false </zeroY>
    <reqX> RX:Bool => RX </reqX>
    <reqY> RY:Bool => RY </reqY>
    <rects> R:Int => R +Int 1 </rects>
    <lines> L:Int => L +Int 2 </lines>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: interactive default is false.
  // - from_prompt: the reported interactive bug should not be fixed by
  //   regressing the noninteractive constructor path.
  // CLAIM: SPAN-HORIZONTAL-NONINTERACTIVE
  claim
    <k> NewSpanSelector(x, false) => .K </k>
    <zeroX> false => false </zeroX>
    <zeroY> ZY:Bool => ZY </zeroY>
    <reqX> RX:Bool => RX </reqX>
    <reqY> RY:Bool => RY </reqY>
    <rects> R:Int => R +Int 1 </rects>
    <lines> L:Int => L </lines>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the old implementation used add_patch for the rectangle and
  //   axvline/axhline for handles.
  // - from_prompt: the observed symptom was x=0 entering the horizontal limits.
  // This claim is a bug-localization witness for V0, not a desired behavior.
  // CLAIM: SPAN-V0-BUG-LOCALIZATION
  claim
    <k> AddPatch(rect, x) ~> AddLine(line, x) ~> AddLine(line, x) => .K </k>
    <zeroX> false => true </zeroX>
    <zeroY> ZY:Bool => ZY </zeroY>
    <reqX> RX:Bool => true </reqX>
    <reqY> RY:Bool => RY </reqY>
    <rects> R:Int => R +Int 1 </rects>
    <lines> L:Int => L +Int 2 </lines>
    [all-path]
endmodule
