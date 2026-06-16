module MINI-MPL-WIDGETS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX

  syntax Axis ::= "x" | "y"
  syntax ArtistKind ::= "rect" | "line"
  syntax Op ::= "NewSpanSelector" "(" Axis "," Bool ")"
              | "NewAxes" "(" Axis ")"
              | "SetupHandles" "(" Axis ")"
              | "AddArtist" "(" ArtistKind "," Axis ")"
              | "AddPatch" "(" ArtistKind "," Axis ")"
              | "AddLine" "(" ArtistKind "," Axis ")"
endmodule

module MINI-MPL-WIDGETS
  imports MINI-MPL-WIDGETS-SYNTAX
  imports BOOL
  imports INT

  configuration
    <k> $PGM:Op </k>
    <zeroX> false </zeroX>
    <zeroY> false </zeroY>
    <reqX> false </reqX>
    <reqY> false </reqY>
    <rects> 0 </rects>
    <lines> 0 </lines>

  // V1 SpanSelector construction: the span patch and, in interactive mode,
  // the two edge handles are helper artists, not plotted data.
  rule <k> NewSpanSelector(A:Axis, true)
        => NewAxes(A) ~> SetupHandles(A) ... </k>
  rule <k> NewSpanSelector(A:Axis, false)
        => NewAxes(A) ... </k>
  rule <k> NewAxes(A:Axis) => AddArtist(rect, A) ... </k>
  rule <k> SetupHandles(A:Axis)
        => AddArtist(line, A) ~> AddArtist(line, A) ... </k>

  // Axes.add_artist appends/draws the artist but does not update dataLim and
  // does not request autoscaling. The zero*/req* cells are intentionally framed.
  rule <k> AddArtist(rect, _:Axis) => .K ... </k>
       <rects> N:Int => N +Int 1 </rects>
  rule <k> AddArtist(line, _:Axis) => .K ... </k>
       <lines> N:Int => N +Int 1 </lines>

  // Legacy V0 mechanisms, included only to localize the reported failure.
  // Axes.add_patch on the span patch could insert the initial 0 into dataLim.
  rule <k> AddPatch(rect, x) => .K ... </k>
       <zeroX> _ => true </zeroX>
       <rects> N:Int => N +Int 1 </rects>
  rule <k> AddPatch(rect, y) => .K ... </k>
       <zeroY> _ => true </zeroY>
       <rects> N:Int => N +Int 1 </rects>

  // Axes.axvline/axhline used by the old handle construction both add line
  // data and may request autoscale when the initial handle position is outside
  // the current data view.
  rule <k> AddLine(line, x) => .K ... </k>
       <zeroX> _ => true </zeroX>
       <reqX> _ => true </reqX>
       <lines> N:Int => N +Int 1 </lines>
  rule <k> AddLine(line, y) => .K ... </k>
       <zeroY> _ => true </zeroY>
       <reqY> _ => true </reqY>
       <lines> N:Int => N +Int 1 </lines>
endmodule
