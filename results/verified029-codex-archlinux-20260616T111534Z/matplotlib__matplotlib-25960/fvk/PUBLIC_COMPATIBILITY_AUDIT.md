# Public Compatibility Audit

Status: static source inspection; not machine-checked.

## Changed Symbols

| Symbol | Public signature changed? | Return shape changed? | Compatibility result |
| --- | --- | --- | --- |
| `FigureBase.subfigures` | No | No | Compatible. Adds private metadata to the internal GridSpec it creates. |
| `SubFigure._redo_transform_rel_fig` | No | No | Compatible. Internal manual bbox arithmetic changed. |
| `FigureBase.add_subfigure` | No | No | Compatible. V2 specifically preserves generic GridSpec spacing behavior. |

## Public Callsite / Consumer Checks

- `FigureBase.subfigures` still passes `wspace` and `hspace` to `GridSpec`, so
  constrained-layout code that reads `gs.wspace`/`gs.hspace` remains compatible.
- `add_subfigure(subplotspec, **kwargs)` still accepts the same inputs. A
  generic GridSpec's subplot spacing is not treated as subfigure spacing unless
  it came from `Figure.subfigures` private metadata.
- No subclass override signature was found or changed in the audited source
  slice.

Result: compatible.
