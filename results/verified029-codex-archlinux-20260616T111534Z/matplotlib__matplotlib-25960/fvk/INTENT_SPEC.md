# Intent Spec

Status: intent-only, before accepting candidate behavior as the specification.

1. `Figure.subfigures(..., wspace=W, hspace=H)` must reserve visible/manual
   space between subfigures when `W` or `H` is nonzero.
2. `W` and `H` are fractions of average subfigure cell width and height.
3. Width and height ratios continue to determine relative cell sizes.
4. Missing manual subfigure spacing defaults to zero rather than rcParam subplot
   spacing.
5. Generic `GridSpec.wspace` / `GridSpec.hspace` should not become subfigure
   spacing for `add_subfigure(gs[i])`; subfigure spacing is a
   `Figure.subfigures` kwarg.
6. Constrained layout may override manual positions by supplying an explicit
   bbox.
