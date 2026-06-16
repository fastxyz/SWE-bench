# Public Compatibility Audit

Status: pass.

## Changed public unit

`matplotlib.offsetbox.AnnotationBbox.draw(self, renderer)`

- Signature changed: no.
- Return shape changed: no explicit return before or after; normal draw still
  returns `None`.
- Child draw protocol changed: no.
- Renderer protocol changed: no. `open_group` and `close_group` already exist
  on `RendererBase` and are implemented by the SVG renderer.
- Subclass/override risk: no public override of `AnnotationBbox.draw` was found
  in the audited source tree. The method body uses only existing renderer hooks.

## Producer/consumer compatibility

- SVG consumers: receive an additional parent `<g>` wrapper for rendered
  `AnnotationBbox` instances. This is the intended fix when a gid is supplied.
- Non-SVG renderers: use no-op group hooks from `RendererBase`, so rendering
  output is unaffected by the new calls.
- Existing child artists: the arrow patch, frame patch, offset box, and image
  draw methods are called with the same arguments and in the same order as
  before V1.

No unhandled public callsite or override blocks the proof.
