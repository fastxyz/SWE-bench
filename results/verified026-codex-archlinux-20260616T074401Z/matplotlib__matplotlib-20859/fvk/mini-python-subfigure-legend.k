requires "domains.md"

module MINI-MPL-SUBFIGURE-LEGEND-SYNTAX
  imports BOOL
  imports LIST

  syntax Parent ::= "axes" | "figure" | "subfigure" | "other"
  syntax LegendObj ::= "legend" "(" Parent ")"
  syntax Outcome ::= "created" "(" Bool "," Parent ")" | "typeError"
  syntax BBoxOutcome ::= "includesLegend" | "missesLegend"

  syntax KItem ::= "legendInit" "(" Parent ")"
                 | "figureBaseLegend" "(" Parent ")"
                 | "appendLegend" "(" Parent ")"
                 | "subfigureTightbbox"

  syntax Bool ::= "isAxes" "(" Parent ")" [function]
                | "isFigureBase" "(" Parent ")" [function]
endmodule

module MINI-MPL-SUBFIGURE-LEGEND
  imports MINI-MPL-SUBFIGURE-LEGEND-SYNTAX
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:K </k>
    <legends> .List </legends>

  rule isAxes(axes) => true
  rule isAxes(figure) => false
  rule isAxes(subfigure) => false
  rule isAxes(other) => false

  rule isFigureBase(axes) => false
  rule isFigureBase(figure) => true
  rule isFigureBase(subfigure) => true
  rule isFigureBase(other) => false

  rule <k> figureBaseLegend(P) => legendInit(P) ~> appendLegend(P) ... </k>

  rule <k> legendInit(P) => created(true, P) ... </k>
    requires isAxes(P)

  rule <k> legendInit(P) => created(false, P) ... </k>
    requires notBool isAxes(P) andBool isFigureBase(P)

  rule <k> legendInit(P) => typeError ... </k>
    requires notBool isAxes(P) andBool notBool isFigureBase(P)

  rule <k> created(ISAXES, P) ~> appendLegend(P) => created(ISAXES, P) ... </k>
       <legends> LS => ListItem(legend(P)) LS </legends>

  rule <k> subfigureTightbbox => includesLegend ... </k>
       <legends> ListItem(legend(subfigure)) LS </legends>

  rule <k> subfigureTightbbox => missesLegend ... </k>
       <legends> .List </legends>
endmodule
