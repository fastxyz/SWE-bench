requires "mini-mpl3d-draw.k"

module AXES3D-VISIBLE-SPEC
  imports MINI-MPL3D-DRAW

  // SPEC-PROVENANCE:
  // - from_prompt: "ax1.set_visible(False)" and "The left axes should be invisible."
  //   => an invisible Axes3D must return before any draw side effect.
  // - from_docs_or_code: Artist.draw says drawing has no effect when get_visible()
  //   is false; Axes.draw checks renderer before visibility.
  // - from_code: Axes3D.draw performs renderer validation, visibility guard, then
  //   3D-specific effects and delegates to base drawing.
  claim
    <k> draw3d(validRenderer, false) => .K </k>
    <events> .List => ListItem(returnInvisible) </events>
    <result> noResult => returned </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Axes.draw raises RuntimeError when renderer is None.
  // - compatibility: Axes3D.draw overrides Axes.draw and should preserve that
  //   renderer precondition independently of visibility.
  claim
    <k> draw3d(noneRenderer, false) => .K </k>
    <events> .List => ListItem(raiseNoRenderer) </events>
    <result> noResult => raised </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: for visible axes, the 3D override must keep the existing
  //   render sequence before delegating to Axes.draw.
  claim
    <k> draw3d(validRenderer, true) => .K </k>
    <events>
      .List => ListItem(unstaleViewLim)
        ListItem(drawPatch)
        ListItem(applyAspect)
        ListItem(computeProjection)
        ListItem(project3dChildren)
        ListItem(draw3dPanes)
        ListItem(draw3dAxes)
        ListItem(delegateBaseDraw)
    </events>
    <result> noResult => returned </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: invisible axes should not remain visible.
  // - from_code: Axes.get_tightbbox returns None for invisible axes.
  // - compatibility: Axes3D.get_tightbbox must preserve that None and must not
  //   union additional 3D-axis bboxes.
  claim
    <k> tightbbox3d(false, noneBBox) => .K </k>
    <events> .List => ListItem(returnInvisibleBBox) </events>
    <result> noResult => bboxNone </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: visible 3D axes extend the base tightbbox with visible 3D axis
  //   tightbboxes.
  claim
    <k> tightbbox3d(true, someBBox) => .K </k>
    <events>
      .List => ListItem(baseTightbbox) ListItem(union3dAxisBBoxes)
    </events>
    <result> noResult => bboxSome </result>
    [all-path]
endmodule
