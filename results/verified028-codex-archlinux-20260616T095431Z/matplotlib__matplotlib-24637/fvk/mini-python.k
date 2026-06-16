module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  syntax Label ::= "annotationbbox"
  syntax Gid ::= "someGid" "(" Id ")" | "noGid"
  syntax Event ::= "openAnn" "(" Gid ")"
                 | "closeAnn"
                 | "updatePositions"
                 | "drawArrow"
                 | "drawPatch"
                 | "drawOffsetBox"
  syntax SvgEvent ::= "svgGroup" "(" Id ")"
                    | "svgAutoGroup" "(" Label ")"
  syntax Stmt ::= "drawAnnotationBbox" "(" Bool "," Bool "," Bool "," Gid ")"
                | "svgOpenGroup" "(" Label "," Gid ")"
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Stmt </k>
    <events> .List </events>
    <svg> .List </svg>
    <stale> true </stale>

  // Abstract normal-return behavior of AnnotationBbox.draw after V1.
  rule
    <k> drawAnnotationBbox(true, true, true, G:Gid) => .K </k>
    <events> ES:List => ES
      ListItem(openAnn(G))
      ListItem(updatePositions)
      ListItem(drawArrow)
      ListItem(drawPatch)
      ListItem(drawOffsetBox)
      ListItem(closeAnn)
    </events>
    <stale> _ => false </stale>

  rule
    <k> drawAnnotationBbox(true, true, false, G:Gid) => .K </k>
    <events> ES:List => ES
      ListItem(openAnn(G))
      ListItem(updatePositions)
      ListItem(drawPatch)
      ListItem(drawOffsetBox)
      ListItem(closeAnn)
    </events>
    <stale> _ => false </stale>

  // Existing early-return behavior: invisible or annotation-clipped paths draw
  // nothing and do not open an annotation group.
  rule
    <k> drawAnnotationBbox(false, CHECK:Bool, HASARROW:Bool, G:Gid) => .K </k>
    <events> ES:List => ES </events>

  rule
    <k> drawAnnotationBbox(true, false, HASARROW:Bool, G:Gid) => .K </k>
    <events> ES:List => ES </events>

  // Abstract RendererSVG.open_group behavior relevant to gid handling.
  rule
    <k> svgOpenGroup(annotationbbox, someGid(G:Id)) => .K </k>
    <svg> S:List => S ListItem(svgGroup(G)) </svg>

  rule
    <k> svgOpenGroup(annotationbbox, noGid) => .K </k>
    <svg> S:List => S ListItem(svgAutoGroup(annotationbbox)) </svg>
endmodule
