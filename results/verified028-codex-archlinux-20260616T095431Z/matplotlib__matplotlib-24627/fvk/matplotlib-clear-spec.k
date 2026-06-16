requires "mini-matplotlib-clear.k"

module MATPLOTLIB-CLEAR-SPEC
  imports MINI-MATPLOTLIB-CLEAR

  // SPEC-PROVENANCE:
  // - from_prompt: "cla(), clf() should unset the `.axes` and `.figure`
  //   attributes of deparented artists" => detached artist has no axes or
  //   figure parent.
  // - from_code: _remove_artist_from_parent clears stale_callback, axes,
  //   figure, and mouseover membership.
  claim <k> detach(artist(someAxes, someFigure, someCallback, mouseover))
        => artist(noAxes, noFigure, noCallback, notMouseover) ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt: `a.cla(); print(l.axes)` must no longer print the old Axes.
  // - from_code: Axes.__clear snapshots children, child axes, legend, titles,
  //   and patch; axis/spine objects are retained in place.
  claim <k> clearAxes(
              axesState(
                ListItem(artist(someAxes, someFigure, someCallback, mouseover)),
                ListItem(artist(someAxes, someFigure, someCallback, notMouseover)),
                someArtist(artist(someAxes, someFigure, someCallback, notMouseover)),
                ListItem(artist(someAxes, someFigure, someCallback, notMouseover)),
                someArtist(artist(noAxes, someFigure, noCallback, notMouseover)),
                ListItem(artist(someAxes, someFigure, someCallback, notMouseover))))
        => axesState(
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)),
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)),
                someArtist(artist(noAxes, noFigure, noCallback, notMouseover)),
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)),
                someArtist(artist(noAxes, noFigure, noCallback, notMouseover)),
                ListItem(artist(someAxes, someFigure, someCallback, notMouseover)))
        ... </k>

  // SPEC-PROVENANCE:
  // - from_prompt: clf() should unset parent attributes of deparented artists.
  // - from_code: FigureBase.clear snapshots subfigures, axes, and figure-level
  //   artist lists and detaches each removed object.
  claim <k> clearFigure(
              figureState(
                ListItem(artist(someAxes, someFigure, someCallback, notMouseover)),
                ListItem(artist(noAxes, someFigure, someCallback, notMouseover)),
                ListItem(artist(noAxes, someFigure, someCallback, notMouseover))))
        => figureState(
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)),
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)),
                ListItem(artist(noAxes, noFigure, noCallback, notMouseover)))
        ... </k>
endmodule
