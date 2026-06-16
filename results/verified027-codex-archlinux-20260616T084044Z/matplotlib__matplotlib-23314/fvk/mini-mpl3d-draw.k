module MINI-MPL3D-DRAW-SYNTAX
  imports BOOL-SYNTAX

  syntax Renderer ::= "noneRenderer" | "validRenderer"
  syntax BBox ::= "noneBBox" | "someBBox"

  syntax Op ::= "draw3d" "(" Renderer "," Bool ")"
              | "tightbbox3d" "(" Bool "," BBox ")"

  syntax Event ::= "raiseNoRenderer"
                 | "returnInvisible"
                 | "unstaleViewLim"
                 | "drawPatch"
                 | "applyAspect"
                 | "computeProjection"
                 | "project3dChildren"
                 | "draw3dPanes"
                 | "draw3dAxes"
                 | "delegateBaseDraw"
                 | "baseTightbbox"
                 | "returnInvisibleBBox"
                 | "union3dAxisBBoxes"

  syntax Result ::= "noResult" | "returned" | "raised"
                  | "bboxNone" | "bboxSome"
endmodule

module MINI-MPL3D-DRAW
  imports MINI-MPL3D-DRAW-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:Op </k>
    <events> .List </events>
    <result> noResult </result>

  rule
    <k> draw3d(noneRenderer, _V:Bool) => .K </k>
    <events> ES:List => ES ListItem(raiseNoRenderer) </events>
    <result> noResult => raised </result>

  rule
    <k> draw3d(validRenderer, false) => .K </k>
    <events> ES:List => ES ListItem(returnInvisible) </events>
    <result> noResult => returned </result>

  rule
    <k> draw3d(validRenderer, true) => .K </k>
    <events>
      ES:List => ES
        ListItem(unstaleViewLim)
        ListItem(drawPatch)
        ListItem(applyAspect)
        ListItem(computeProjection)
        ListItem(project3dChildren)
        ListItem(draw3dPanes)
        ListItem(draw3dAxes)
        ListItem(delegateBaseDraw)
    </events>
    <result> noResult => returned </result>

  rule
    <k> tightbbox3d(false, noneBBox) => .K </k>
    <events> ES:List => ES ListItem(returnInvisibleBBox) </events>
    <result> noResult => bboxNone </result>

  rule
    <k> tightbbox3d(true, someBBox) => .K </k>
    <events>
      ES:List => ES
        ListItem(baseTightbbox)
        ListItem(union3dAxisBBoxes)
    </events>
    <result> noResult => bboxSome </result>
endmodule
