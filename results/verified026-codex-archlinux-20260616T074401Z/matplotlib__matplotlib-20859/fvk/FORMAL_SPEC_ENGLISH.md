# Formal Spec in English

C-001: Starting from `FigureBase.legend()` on a `subfigure` parent creates a
legend with `isaxes == False`, sets the legend parent to the subfigure, and
adds that legend to the subfigure's legend list.

C-002: Starting from `Legend.__init__` on an `axes` parent creates a legend
with `isaxes == True`.  Starting from `Legend.__init__` on a concrete `figure`
parent creates a legend with `isaxes == False`.

C-003: Starting from `Legend.__init__` on an unrelated `other` parent raises
the modeled `typeError` outcome and does not add a legend.

C-004: Starting from a subfigure whose legend list contains its legend, the
subfigure tight-bbox abstraction reaches `includesLegend`.

C-005: The proof is partial correctness over the modeled parent-class and
ownership behavior.  It does not claim machine-checked renderer geometry or
pixel output equality.
