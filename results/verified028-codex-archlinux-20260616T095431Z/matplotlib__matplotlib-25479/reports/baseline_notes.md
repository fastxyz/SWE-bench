# Baseline Notes

## Root Cause

`pyplot.set_cmap` resolved the caller's argument to a `Colormap` object with
`get_cmap(cmap)`, then stored `cmap.name` in `rcParams["image.cmap"]`.

When a colormap is registered under a name that differs from the colormap
object's own `.name`, looking up the registered name returns a `Colormap` whose
`.name` is still the object's original internal name. `set_cmap` therefore
stored that internal name as the default. Later image creation, such as
`imshow` without an explicit `cmap`, looked up `rcParams["image.cmap"]` in the
colormap registry and failed if the internal name was not itself registered.

## Files Changed

- `repo/lib/matplotlib/pyplot.py`: Preserved the caller-provided string name
  before resolving it to a `Colormap`. After validation and lookup via
  `get_cmap`, `set_cmap` now stores that registered string in `image.cmap`.
  Passing a `Colormap` object keeps the previous behavior of storing the
  object's `.name`.

## Assumptions

- The issue concerns string-based pyplot usage, where the caller supplies a
  registered colormap name or alias and expects that name to become the pyplot
  default.
- `get_cmap` should remain the validation point, so invalid strings still raise
  before `rcParams` is updated.
- Existing behavior for passing a raw `Colormap` object should remain unchanged
  because there is no registered alias available from the object alone.

## Alternatives Considered

- Renaming the copied colormap inside the registry to match the registration
  key was rejected because the registry currently preserves the colormap's
  object-level metadata and may intentionally allow aliases.
- Changing the rcParam validator to map colormap objects or names differently
  was rejected as broader than necessary; the bad value is introduced by
  `pyplot.set_cmap`, so the fix is localized there.
- Updating `ScalarMappable` or image creation paths was rejected because they
  correctly rely on `rcParams["image.cmap"]` containing a valid registered name
  when no explicit colormap is supplied.
