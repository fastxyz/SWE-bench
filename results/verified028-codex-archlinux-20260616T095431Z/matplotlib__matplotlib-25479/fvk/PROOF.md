# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were run.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-pyplot-cmap.k --backend haskell
kast --backend haskell fvk/pyplot-set-cmap-spec.k
kprove fvk/pyplot-set-cmap-spec.k
```

Expected machine-check result after installing/running K: `#Top` for all
claims.

## Model Summary

The K model abstracts the audited path to the state relevant to the bug:

- registry lookup by registered string key;
- `rcParams["image.cmap"]` as either `rcName(name)` or `rcObj(cmap)`;
- optional current image update.

This abstraction preserves the observable axis under verification: whether the
future default is resolved by the registered alias or by an object/default
value. It intentionally ignores rendering and array data, which are not
contributors to the reported failure.

## Proof Sketch By Obligation

### PO-01 and PO-02: registered string alias

Start with `setCmap(str(ALIAS))`, registry `REG`, and
`hasKey(REG, ALIAS)`.

1. The string rule rewrites the computation to
   `applySetCmap(someName(ALIAS), lookup(REG, ALIAS))`.
2. The rc assignment rule for `someName(ALIAS)` rewrites the rc cell to
   `rcName(ALIAS)`, not to any field of the colormap object.
3. If the computation continues with `defaultCmap`, the default lookup rule for
   `rcName(ALIAS)` returns `lookup(REG, ALIAS)`.
4. Therefore an internal colormap name mismatch cannot affect the future
   default lookup path.

This discharges claims C1 and the alias part of C2.

### PO-03: current-image update

Continue from the same successful string lookup state, but with
`<currentImage> image(IMG) </currentImage>`.

1. `setCmap(str(ALIAS))` resolves to colormap `C = lookup(REG, ALIAS)`.
2. The rc assignment stores `rcName(ALIAS)`.
3. `updateImage(C)` with a current image rewrites
   `<imageCmaps> M </imageCmaps>` to `<imageCmaps> M[IMG <- C] </imageCmaps>`.
   The statement computation completes as `.K`.

Thus the existing pyplot side effect is preserved.

### PO-04 and PO-05: `Colormap` object defaults

Start with `setCmap(obj(C))`.

1. The object rule rewrites directly to `applySetCmap(noName, C)`, matching
   `get_cmap` returning the object itself.
2. The rc assignment rule for `noName` rewrites the rc cell to `rcObj(C)`.
3. A following `defaultCmap` with `rcObj(C)` returns `C` directly.

The source code mirrors this:

- `set_cmap` stores the resolved `cmap` object when the original input was not
  a string.
- `ColormapRegistry.get_cmap(None)` and `_ensure_cmap(None)` load the rcParam,
  then return it if it is already a `Colormap`.

### PO-06: invalid string names

Start with `setCmap(str(BAD))` and `notBool hasKey(REG, BAD)`.

1. The invalid-name rule rewrites to `unknownCmap`.
2. The rc cell is framed as `RC => RC`.
3. The image-cmap map is framed as `M => M`.

The source code order discharges the same property because `get_cmap(cmap)` is
called before `rc(...)`, `gci()`, or `im.set_cmap(...)`.

## Adequacy Result

The English meaning of C1-C5 matches the public intent obligations in
`fvk/SPEC.md`; no claim preserves the pre-fix behavior where `cmap.name`
overrode the registered alias. The broader object-valued rcParam claims are
supported by public Matplotlib documentation and validator code, not by hidden
tests or candidate behavior alone.

## Test Guidance

No tests were removed or run. If the K claims are later machine-checked, unit
tests that only assert the in-domain behavior of C1-C4 become candidates for
conditional redundancy. Integration/rendering tests, invalid-name behavior
tests, and tests covering real Matplotlib object-copy semantics should be kept.
