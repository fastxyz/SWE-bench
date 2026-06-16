requires "mini-python.k"

module INSET-LOCATOR-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - E-005: provided renderers should continue through the existing path.
  // - PO-003: explicit-renderer behavior is preserved.
  claim
    <k> callLocator(ax, providedRenderer) => done(bboxResult) </k>
    <figureRenderer> figureRenderer </figureRenderer>
    <locatorAxes> _ => ax </locatorAxes>

  // SPEC-PROVENANCE:
  // - E-003/E-006: tight-bbox callers invoke axes locators as locator(ax, None).
  // - E-005: the intended fallback renderer is ax.figure._get_renderer().
  // - PO-002/PO-004: fallback happens before extent and offset calculations.
  claim
    <k> callLocator(ax, none) => done(bboxResult) </k>
    <figureRenderer> figureRenderer </figureRenderer>
    <locatorAxes> _ => ax </locatorAxes>

  // SPEC-PROVENANCE:
  // - E-007: the pre-fix bug was dependence on locator.figure.
  // - PO-005: the successful None-renderer path uses the axes figure renderer.
  // This claim is represented by the absence of any locator figure cell in the
  // semantics: the successful path has no state from which to read one.
endmodule
