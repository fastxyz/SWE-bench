requires "mini-python.k"

module ANNOTATIONBBOX-SPEC
  imports MINI-PYTHON
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "ab.set_gid('My_label')" and SVG lacks the label
  //   => a supplied parent gid must reach the renderer on the SVG path.
  // - from_hint: "wrap the entire AnnotationBbox in a svg element with that gid"
  //   => all child draw events are between openAnn and closeAnn.
  // - from_code: AnnotationBbox.draw draws arrow, patch, offsetbox in this order.
  // CLAIM: DRAW-VISIBLE-WITH-GID-ARROW
  claim
    <k> drawAnnotationBbox(true, true, true, someGid(G:Id)) => .K </k>
    <events> ES:List => ES
      ListItem(openAnn(someGid(G)))
      ListItem(updatePositions)
      ListItem(drawArrow)
      ListItem(drawPatch)
      ListItem(drawOffsetBox)
      ListItem(closeAnn)
    </events>
    <svg> SVG:List </svg>
    <stale> _ => false </stale>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: grouping applies to the entire AnnotationBbox, not only
  //   arrow-bearing instances.
  // - from_code: when arrow_patch is absent, patch and offsetbox remain.
  // CLAIM: DRAW-VISIBLE-WITH-GID-NO-ARROW
  claim
    <k> drawAnnotationBbox(true, true, false, someGid(G:Id)) => .K </k>
    <events> ES:List => ES
      ListItem(openAnn(someGid(G)))
      ListItem(updatePositions)
      ListItem(drawPatch)
      ListItem(drawOffsetBox)
      ListItem(closeAnn)
    </events>
    <svg> SVG:List </svg>
    <stale> _ => false </stale>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code_pattern: grouped composite artists open groups after visibility
  //   checks.
  // - from_code: AnnotationBbox.draw already returned early when invisible.
  // CLAIM: DRAW-SKIPPED-INVISIBLE
  claim
    <k> drawAnnotationBbox(false, CHECK:Bool, HASARROW:Bool, G:Gid) => .K </k>
    <events> ES:List => ES </events>
    <svg> SVG:List </svg>
    <stale> STALE:Bool </stale>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: AnnotationBbox.draw already returned early when _check_xy fails.
  // - from_intent: no SVG element is required for an annotation that is not drawn.
  // CLAIM: DRAW-SKIPPED-CLIPPED
  claim
    <k> drawAnnotationBbox(true, false, HASARROW:Bool, G:Gid) => .K </k>
    <events> ES:List => ES </events>
    <svg> SVG:List </svg>
    <stale> STALE:Bool </stale>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_backend_svg: open_group writes writer.start('g', id=gid) when gid is
  //   supplied.
  // - from_prompt: supplied gid My_label must be present in the SVG output.
  // CLAIM: SVG-OPEN-GROUP-GID
  claim
    <k> svgOpenGroup(annotationbbox, someGid(G:Id)) => .K </k>
    <events> ES:List </events>
    <svg> S:List => S ListItem(svgGroup(G)) </svg>
    <stale> STALE:Bool </stale>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_backend_svg: no gid falls back to a generated id based on label.
  // - from_audit: public intent does not specify the generated spelling.
  // CLAIM: SVG-OPEN-GROUP-NO-GID
  claim
    <k> svgOpenGroup(annotationbbox, noGid) => .K </k>
    <events> ES:List </events>
    <svg> S:List => S ListItem(svgAutoGroup(annotationbbox)) </svg>
    <stale> STALE:Bool </stale>
    [all-path]
endmodule
