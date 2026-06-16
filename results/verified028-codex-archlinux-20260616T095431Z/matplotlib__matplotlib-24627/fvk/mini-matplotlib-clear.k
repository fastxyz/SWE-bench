module MINI-MATPLOTLIB-CLEAR-SYNTAX
  imports BOOL
  imports LIST

  syntax AxRef ::= "noAxes" | "someAxes"
  syntax FigRef ::= "noFigure" | "someFigure"
  syntax Callback ::= "noCallback" | "someCallback"
  syntax Mouseover ::= "notMouseover" | "mouseover"

  syntax Artist ::= "artist" "(" AxRef "," FigRef "," Callback "," Mouseover ")"
  syntax MaybeArtist ::= "noArtist" | "someArtist" "(" Artist ")"
  syntax AxesState ::= "axesState" "(" List "," List "," MaybeArtist ","
                       List "," MaybeArtist "," List ")"
  syntax FigureState ::= "figureState" "(" List "," List "," List ")"

  syntax Artist ::= "detach" "(" Artist ")" [function]
  syntax List ::= "detachAll" "(" List ")" [function]
  syntax MaybeArtist ::= "detachMaybe" "(" MaybeArtist ")" [function]
  syntax AxesState ::= "clearAxes" "(" AxesState ")" [function]
  syntax FigureState ::= "clearFigure" "(" FigureState ")" [function]
endmodule

module MINI-MATPLOTLIB-CLEAR
  imports MINI-MATPLOTLIB-CLEAR-SYNTAX

  configuration <k> $PGM:K </k>

  rule detach(artist(_, _, _, _))
    => artist(noAxes, noFigure, noCallback, notMouseover)

  rule detachAll(.List) => .List
  rule detachAll(ListItem(A:Artist) REST:List)
    => ListItem(detach(A)) detachAll(REST)

  rule detachMaybe(noArtist) => noArtist
  rule detachMaybe(someArtist(A:Artist)) => someArtist(detach(A))

  rule clearAxes(axesState(CHILDREN:List, CHILD_AXES:List,
                           LEGEND:MaybeArtist, TITLES:List,
                           PATCH:MaybeArtist, RETAINED:List))
    => axesState(detachAll(CHILDREN), detachAll(CHILD_AXES),
                 detachMaybe(LEGEND), detachAll(TITLES),
                 detachMaybe(PATCH), RETAINED)

  rule clearFigure(figureState(AXES:List, FIG_ARTISTS:List, SUBFIGS:List))
    => figureState(detachAll(AXES), detachAll(FIG_ARTISTS),
                   detachAll(SUBFIGS))
endmodule
