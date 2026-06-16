module MINI-PATCH-LIMITS-SYNTAX
  imports BOOL
  imports INT
  imports LIST

  syntax Point ::= pt(Int, Int)
  syntax Path ::= path(List)
  syntax Segs ::= segs(List)
  syntax List ::= limitPointList(Path) [function]

  syntax KItem ::= iterBezier(Path, Bool)
                 | updatePatchLimits(Path)

  syntax Bool ::= coversAllVertices(Path, List) [function]
                | containsMaxDensity(Path, List) [function]
                | isStepHistPath(Path) [function]
endmodule

module MINI-PATCH-LIMITS
  imports MINI-PATCH-LIMITS-SYNTAX

  configuration <k> $PGM:K </k>

  // Abstract mini-semantics for the audited slice:
  // - simplify=false preserves the original path vertices in the segment
  //   stream used for data-limit computation.
  // - limitPointList(path(VS)) represents endpoints plus any Bezier extrema.
  // The real Matplotlib implementation obtains these via iter_bezier and
  // curve([0, *dzeros, 1]).
  rule <k> iterBezier(path(VS), false) => segs(VS) ... </k>
  rule limitPointList(path(VS)) => VS [simplification]
  rule <k> updatePatchLimits(P) => limitPointList(P) ... </k>
endmodule
