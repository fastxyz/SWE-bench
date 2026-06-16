# Iteration Guidance

Status: V2 source fix applied; proof constructed, not machine-checked.

## Code Decision

Keep the V2 source change in `repo/sphinx/util/docfields.py`:

```python
if not argtype.endswith(','):
```

This addresses F2 and obligations O1/O2 while preserving O3. The V1 Napoleon changes were removed because F1 showed they fixed type visibility by changing the grouped output form.

## Tests To Add Or Keep Later

Do not edit tests in this benchmark phase. In a normal development pass, add or keep coverage for:

- A NumPy docstring parameter field `x1, x2 : array_like, optional` rendered through the Python domain; expected visible name `x1, x2` and visible type text including `optional`.
- A paired docutils field list `:param x1, x2:` / `:type x1, x2:` transformed by `DocFieldTransformer`; expected no synthetic inline type `x1,` for `x2`.
- A documented inline typed field `:param str sender:`; expected type `str` remains attached to `sender`.
- Existing Napoleon string-level expectations around `_format_docutils_params()`; expected unchanged output because V2 no longer edits Napoleon formatting.

## Commands For A Future Verification Environment

```sh
kompile fvk/mini-docfields.k --backend haskell
kast --backend haskell fvk/docfield-transformer-spec.k
kprove fvk/docfield-transformer-spec.k
```

Run the normal Sphinx test suite only in an environment where project code execution is allowed.

## Residual Risk

- The K model is an intentional abstraction of Sphinx/Docutils nodes and field lists. It models exact field-key preservation and type attachment, not full node rendering.
- The proof is partial correctness over the modeled transformation branch; it does not prove termination or full Sphinx rendering.
- Because no execution is allowed here, hidden integration behavior remains unobserved. The public compatibility audit reduces that risk by preserving documented `:param type name:` behavior.
