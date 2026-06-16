# Public Compatibility Audit

Status: pass.

## Changed symbol

- `mpl_toolkits.axes_grid1.inset_locator.AnchoredLocatorBase.__call__`

## Compatibility facts

- Signature remains `__call__(self, ax, renderer)`.
- Return shape remains a `TransformedBbox`.
- Public factory functions `inset_axes` and `zoomed_inset_axes` are unchanged.
- `_add_inset_axes` behavior and axes constructor arguments are unchanged.
- No virtual dispatch call was given a new keyword argument.
- No test files or public API stubs were modified.

## Callsite / subclass coverage

- `inset_axes(...)` constructs `AnchoredSizeLocator`, which inherits the changed
  base method.
- `zoomed_inset_axes(...)` constructs `AnchoredZoomLocator`, which inherits the
  changed base method.
- Existing callers that already pass a renderer continue through the same
  effective-renderer path.
- Callers that pass `None` now use the axes figure renderer, matching the public
  intent and Matplotlib's existing omitted-renderer pattern.

No compatibility finding blocks V1.
