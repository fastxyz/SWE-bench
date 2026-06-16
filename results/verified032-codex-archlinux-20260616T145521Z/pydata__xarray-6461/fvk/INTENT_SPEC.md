# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Required behavior

1. `xr.where(cond, x, y, keep_attrs=True)` must not fail only because `x` is a scalar.
2. When `keep_attrs=True`, top-level `xr.where` keeps attrs from `x`, the second argument.
3. If `x` is scalar or otherwise has no xarray attrs, the kept attrs are empty. Attrs from `cond` or `y` are not a fallback source for `x`.
4. Existing `where` broadcasting, alignment, result-type priority, and non-`True` `keep_attrs` behavior are out of scope for this bug and must remain unchanged.
5. The public function signature must remain compatible: `where(cond, x, y, keep_attrs=None)`.

## Default-domain assumptions

1. Public attrs behavior is content-based. The intent requires the resulting attrs mapping to equal the attrs of `x`; it does not require object identity with the original attrs dictionary.
2. Partial correctness is sufficient for this audit. The helper iterates over finite attrs lists produced by xarray internals; termination is not separately proved by a runtime tool in this environment.
