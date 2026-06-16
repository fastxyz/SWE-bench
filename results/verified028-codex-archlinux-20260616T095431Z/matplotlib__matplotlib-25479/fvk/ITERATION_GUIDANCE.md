# Iteration Guidance

Status: V2 source changes are justified by `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`.

## Applied Changes

1. Keep the caller's registered string key on the `set_cmap(str)` path.
   Justification: F-01, F-02, PO-01, PO-02.

2. Store a `Colormap` object directly in `image.cmap` on the
   `set_cmap(Colormap)` path.
   Justification: F-03, PO-04.

3. Teach `ColormapRegistry.get_cmap(None)` and `cm._ensure_cmap(None)` to
   return an object-valued `image.cmap` directly.
   Justification: F-03, PO-05.

4. Preserve invalid-name ordering by leaving lookup before mutation.
   Justification: F-04, PO-06.

## Suggested Tests To Add Later

Do not add or run tests in this benchmark phase. For a normal development
follow-up, add tests covering:

- Register a colormap under alias `alias` while `cmap.name != alias`; call
  `plt.set_cmap(alias)` and confirm a later default image uses the alias entry.
- Confirm `plt.rcParams["image.cmap"] == alias` after string-based
  `plt.set_cmap(alias)`.
- Pass an unregistered `Colormap` instance to `plt.set_cmap(cmap)` and confirm
  later default colormap resolution returns that object without looking up
  `cmap.name`.
- Set `mpl.rcParams["image.cmap"]` directly to a `Colormap` object and confirm
  both `mpl.colormaps.get_cmap(None)` and image default resolution accept it.
- Confirm an invalid string name raises before changing `image.cmap`.

## Residual Work

- Run the emitted K commands only in an environment where K execution is
  allowed.
- Run the Matplotlib test suite only in a normal development environment.
- Keep integration tests until the constructed proof is machine-checked and the
  proof scope is mapped to specific tests.
