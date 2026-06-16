# Public Evidence Ledger

E-001, prompt: "Adding a legend to a `SubFigure` doesn't work."  Semantic
obligation: support the `SubFigure.legend()` path.

E-002, prompt: "I'd expect this to work and produce a legend" and "allow a
legend per subfigure."  Semantic obligation: successful legend creation scoped
to the subfigure.

E-003, prompt hint: "Changing L437 here to check against `FigureBase` fixes
it."  Semantic obligation: `FigureBase` is the intended acceptance class.

E-004, maintainer hint: "Yep that was just an oversight, not a design decision
;-)"  Semantic obligation: rejecting `SubFigure` is a bug, not intended
behavior.

E-005, source docstring: `FigureBase` is the base class for `Figure` and
`SubFigure` containing methods that add artists and create axes.  Semantic
obligation: use the shared figure-like abstraction.

E-006, source: `FigureBase.legend()` constructs `Legend(self, ...)`, appends to
`self.legends`, sets the remove method, marks `self.stale`, and returns the
legend.  Semantic obligation: the constructor accepts every valid
`FigureBase.legend()` receiver.

E-007, public hint: the follow-up bbox discussion says the top-level default
extra artists do not include the legend directly, and the later maintainer hint
says the subfigure bbox should include the legend.  Semantic obligation: audit
ownership and tight-bbox reachability.
