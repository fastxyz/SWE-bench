requires "mini-python-subfigure-legend.k"

module SUBFIGURE-LEGEND-SPEC
  imports MINI-MPL-SUBFIGURE-LEGEND

  // SPEC-PROVENANCE:
  // - E-001/E-002: "subfig.legend()" should work and produce a legend.
  // - E-003: the intended repair is checking against FigureBase.
  // - E-006: FigureBase.legend appends the created legend to self.legends.
  claim
    <k> figureBaseLegend(subfigure) => created(false, subfigure) </k>
    <legends> .List => ListItem(legend(subfigure)) .List </legends>

  // SPEC-PROVENANCE:
  // - E-005/E-006: existing Axes.legend and Figure.legend behavior must remain.
  claim
    <k> legendInit(axes) => created(true, axes) </k>
    <legends> .List </legends>

  claim
    <k> legendInit(figure) => created(false, figure) </k>
    <legends> .List </legends>

  // SPEC-PROVENANCE:
  // - E-001/E-004 only make SubFigure in-domain; arbitrary parents remain invalid.
  claim
    <k> legendInit(other) => typeError </k>
    <legends> .List </legends>

  // SPEC-PROVENANCE:
  // - E-007: the top-level bbox path should reach the SubFigure, whose bbox
  //   includes its owned legend.
  // - Source: FigureBase.get_children includes *self.legends.
  claim
    <k> subfigureTightbbox => includesLegend </k>
    <legends> ListItem(legend(subfigure)) .List </legends>
endmodule
