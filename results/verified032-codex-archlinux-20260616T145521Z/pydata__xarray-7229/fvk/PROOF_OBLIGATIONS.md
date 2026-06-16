# FVK Proof Obligations

Status: constructed; not machine-checked.

| ID | Obligation | Evidence | V1 discharge |
| --- | --- | --- | --- |
| O1 | Preserve value semantics: result values are `where(cond, x, y)`. | `where` docstring and NumPy correspondence. | V1 wrapper `func(x_, cond_, y_)` returns `duck_array_ops.where(cond_, x_, y_)`; only internal argument order changes. |
| O2 | Top-level result attrs come from `x` for `keep_attrs=True`. | Docstring: "If True, keep the attrs of `x`." | V1 captures `x_attrs = dict(getattr(x, "attrs", {}))` and assigns `result.attrs = dict(x_attrs)` when attrs exist. |
| O3 | Dataset result data variable attrs come from matching variables in Dataset `x`; otherwise from `attrs(x)`. | Dataset/DataArray method consistency and distinction between Dataset attrs and variable attrs. | V1 iterates `result.data_vars`; if `x` has `data_vars`, it uses `x[name].attrs`, otherwise `x_attrs`. |
| O4 | Coordinate attrs are preserved as coordinate attrs and are not overwritten by data attrs from `x`. | Problem statement and MVCE expected `time.attrs`. | V1 calls `apply_ufunc` as `(x, cond, y, keep_attrs=True)`, using normal `"override"` merge on coordinate variables rather than a callable returning data attrs. |
| O5 | Scalar/unlabeled `x` contributes empty attrs and cannot cause attrs from `cond` or `y` to be selected. | Public hint rejecting `attrs[1]` for scalar `x`. | `getattr(x, "attrs", {})` is `{}` for scalar `x`; post-normalization overwrites any temporary attrs selected by `apply_ufunc`. |
| O6 | Non-true `keep_attrs` behavior remains unchanged. | Public API compatibility. | V1 returns through the original `apply_ufunc(duck_array_ops.where, cond, x, y, ..., keep_attrs=keep_attrs)` path when `keep_attrs is not True`. |
| O7 | Public API shape remains compatible. | Existing callers use `where(cond, x, y, keep_attrs=None)`. | No signature change, no new public helper, no test changes. |
| O8 | Proof scope is limited to attr propagation, not full xarray execution semantics. | The issue is about attrs; `apply_ufunc` already owns alignment/value dispatch. | The mini-model abstracts established value/alignment semantics and keeps attr maps observable. |

## Abstract K Claim Sketch

The constructed K claim represented in `fvk/PROOF.md` is:

```k
claim
  <k> whereKeepAttrsTrue(COND, X, Y)
   => result(
        whereValue(COND, X, Y),
        attrsOf(X),
        dataAttrsFromX(X, resultDataVars(X, COND, Y)),
        coordAttrsOverride(X, COND, Y)
      )
  </k>
```

Where:

- `whereValue(COND, X, Y)` preserves `duck_array_ops.where(COND, X, Y)`.
- `attrsOf(scalar) = .Map`.
- `coordAttrsOverride(X, COND, Y)` selects coordinate attrs with `x`, then
  `cond`, then `y` priority for coordinates supplied by those objects.
- `dataAttrsFromX` copies Dataset variable attrs from `X` when available and
  otherwise uses `attrsOf(X)`.

The proof obligations above are the English adequacy gate for that claim.

