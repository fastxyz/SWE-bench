# Public Evidence Ledger

| Id | Source | Quote / Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`wspace` and `hspace` in `Figure.subfigures` do nothing." | Spacing arguments must change subfigure positions. | Encoded in SPEC and claims. |
| E2 | `Figure.subfigures` docstring | Spacing is "reserved for space between subfigures" and expressed as a fraction of average subfigure width/height. | Use average-cell denominator semantics. | Encoded in SPEC and claims. |
| E3 | Public hint | "position logic could be borrowed from Axes" with `GridSpec.get_grid_positions` reference. | Use GridSpec-style cell/separator arithmetic. | Encoded in SPEC and claims. |
| E4 | Public hint | "Can we just make the default wspace for subfigures be zero?" | Manual default spacing is zero. | Encoded in SPEC and claims. |
| E5 | Public hint | "subfigures ignores the grid spec wspace ... if we want a wspace for a set of subfigures that be a kwarg of the subfigure call." | Separate subfigure spacing from generic GridSpec spacing. | V1 failed; V2 fixed. |
| E6 | Source | `_constrained_layout.reposition_axes` calls `_redo_transform_rel_fig(bbox=...)`. | Explicit bbox path remains an override. | Encoded as frame condition. |
