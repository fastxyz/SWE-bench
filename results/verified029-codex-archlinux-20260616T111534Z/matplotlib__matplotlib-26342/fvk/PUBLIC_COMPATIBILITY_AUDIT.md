# Public Compatibility Audit

Changed public symbol: `matplotlib.contour.ContourSet.set_paths`.

## Signature

- V1/V2 signature: `set_paths(self, paths)`.
- This matches the inherited `Collection.set_paths(paths)` signature and the
  public proposal.
- No keyword-only or required extra arguments were added.

## Callers and subclasses

- `QuadContourSet` inherits from `ContourSet`, so `Axes.contour` and
  `Axes.contourf` gain the setter.
- `TriContourSet` inherits from `ContourSet`, so triangular contour APIs gain
  the setter.
- No public override in `repo/lib/matplotlib/tri/_tricontour.py` conflicts with
  the signature.
- No base `Collection` behavior was changed; existing `PathCollection`,
  `PolyCollection`, `LineCollection`, mesh, and patch collection setters keep
  their specialized behavior.

## Producer/consumer shape

- `ContourSet.draw`, labeling helpers, nearest-contour lookup, 3D contour
  extension, and `get_paths` consume `_paths`; replacing `_paths` preserves
  their expected producer shape.
- Deprecated `collections`, `allsegs`, and `allkinds` derive old-style views
  from `_paths`; V2 invalidates the cached split view when paths are replaced.

Verdict: compatible.

