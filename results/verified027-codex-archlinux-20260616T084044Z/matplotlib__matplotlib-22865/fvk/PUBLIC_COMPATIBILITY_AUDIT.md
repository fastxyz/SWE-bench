# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed symbol

- `matplotlib.colorbar.Colorbar._add_solids`

## Compatibility result

- Public constructor signatures are unchanged.
- The `drawedges` parameter type and meaning are unchanged.
- The `extend` accepted values are unchanged.
- `ColorbarBase = Colorbar` remains unchanged.
- No callsite or subclass override is affected: `_add_solids` is an internal
  helper called by `Colorbar._draw_all` with the same `(X, Y, C)` arguments as
  before.
- The `self.dividers` object remains the same `LineCollection`; only the
  selected segment rows differ when an extension side exists.
- Existing behavior for `drawedges=False` and for non-extended sides is
  preserved.

Compatibility status: pass.
