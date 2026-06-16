# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Scope

Target: `repo/xarray/core/computation.py`, function `where(cond, x, y, keep_attrs=None)`, specifically the `keep_attrs is True` adapter that feeds `apply_ufunc`.

This spec abstracts xarray arrays and variables down to attrs sources and merge attrs lists. That is sufficient for this issue because the observed failure is an attrs-list indexing failure before the numerical `where` result is relevant.

## Public Intent Ledger

The ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

| ID | Obligation |
|---|---|
| E1 | Scalar `x` is in-domain for `xr.where(..., keep_attrs=True)`. |
| E2 | The reported bug is the positional `attrs[1]` assumption raising `IndexError`. |
| E3 | Users should not need `keep_attrs=False` as a workaround. |
| E4 | `keep_attrs=True` means keep attrs from `x`, the second argument. |
| E5 | The `x` parameter is documented as scalar, array, Variable, DataArray, or Dataset. |
| E6 | `apply_ufunc` merge attrs lists omit raw scalars, so `where` must not infer x attrs from a fixed list index. |
| E7 | Public signature and call protocol must remain compatible. |

## Formal Contract

For the `keep_attrs is True` branch:

1. Build the set/list of attrs sources associated with the original `x` argument.
2. If `x` has no attrs sources, the generated `keep_attrs` callable returns `{}` for any nonempty merge attrs list and never indexes a missing list position.
3. If a current merge attrs list contains attrs content belonging to `x`, the callable returns attrs with that content.
4. If a current merge attrs list contains no attrs content belonging to `x`, the callable returns `{}`.
5. Non-`True` values of `keep_attrs` are passed through exactly as before.
6. The public function signature and `apply_ufunc` call shape are unchanged.

## Formal Artifacts

`fvk/mini-python-where-attrs.k` defines a small K fragment for attrs-source selection. `fvk/xarray-where-attrs-spec.k` contains reachability claims for the scalar reproducer, scalar `x` with `y` attrs present, x attrs preservation, and no-x-source fallback.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-python-where-attrs.k --backend haskell
kast --backend haskell fvk/xarray-where-attrs-spec.k
kprove fvk/xarray-where-attrs-spec.k
```
