# Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Preserve registered string alias in `pyplot.set_cmap`

For every registered name `N` and registry result `C`, calling
`set_cmap(N)` must write `N` to `rcParams["image.cmap"]`, not `C.name`.

Source support:

- Evidence E1, E2, E3 in `fvk/SPEC.md`.
- K claim C1 in `fvk/pyplot-set-cmap-spec.k`.

Code discharge:

- `repo/lib/matplotlib/pyplot.py` stores `cmap_name = cmap` before lookup when
  the input is a string.
- The rc assignment uses `cmap_name if cmap_name is not None else cmap`.

## PO-02: Future default lookup resolves the registered alias

After `set_cmap(N)` succeeds for registered string `N`, a subsequent default
colormap lookup must resolve through the registry entry for `N`.

Source support:

- Evidence E1 and E3.
- K claim C1.

Code discharge:

- String inputs leave `rcParams["image.cmap"]` as `N`.
- `cm._ensure_cmap(None)` and `cm._get_cmap(None)` use the rcParam value for
  default resolution.

## PO-03: Preserve current-image side effect

If `gci()` returns an image, `set_cmap` must apply the resolved colormap object
to that image.

Source support:

- Evidence E4.
- K claim C2.

Code discharge:

- `pyplot.set_cmap` still calls `im.set_cmap(cmap)` after the rc update when
  `im is not None`.

## PO-04: Support `set_cmap(Colormap)` as a default colormap

For any `Colormap` object `C`, calling `set_cmap(C)` must make `C` the default
colormap without requiring `C.name` to be a registered name.

Source support:

- Evidence E4, E5, E6.
- K claim C3.

Code discharge:

- `pyplot.set_cmap` now stores `cmap` itself in `image.cmap` when the original
  input was not a string.

## PO-05: Default lookup accepts object-valued `image.cmap`

When `rcParams["image.cmap"]` is a `Colormap` object, default lookup helpers
must return that object directly.

Source support:

- Evidence E5 and E6.
- K claim C4.

Code discharge:

- `ColormapRegistry.get_cmap(None)` now loads the rcParam into `cmap`, then
  returns it if it is already a `Colormap`.
- `cm._ensure_cmap(None)` now performs the same object check after loading the
  rcParam.

## PO-06: Invalid string names fail before mutation

For an unregistered string `BAD`, `set_cmap(BAD)` must fail during colormap
resolution and leave `rcParams["image.cmap"]` and current-image cmap unchanged.

Source support:

- Evidence E7.
- K claim C5.

Code discharge:

- `pyplot.set_cmap` calls `get_cmap(cmap)` before `rc(...)` and before `gci()`.

## PO-07: Public API shape is unchanged

The fix must not change public function signatures, remove accepted input
classes, or modify tests.

Source support:

- Public compatibility audit in `fvk/SPEC.md`.

Code discharge:

- No signatures changed.
- No test files changed.
