# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or `kprove` were run.

## Claims

The K claims in `fvk/xarray-where-attrs-spec.k` cover:

1. Scalar `x` with a singleton attrs list from `cond`.
2. Scalar `x` with attrs from both `cond` and `y`.
3. Xarray `x` whose attrs participate in the current merge.
4. A merge where no attrs source from `x` participates.

## Proof Sketch

The legacy implementation used a selector equivalent to `oldSelectSecond(attrs)`, which has a rewrite only for lists with at least two elements. On the reproducer, the merge attrs list can be `ListItem(attrs("cond"))`, so the old selector is stuck. In Python this stuck state is the observed `IndexError`.

V1 first constructs `x_attrs`, the list of attrs sources associated with the original `x` argument. If `x` is scalar, this list is empty. The generated callable then iterates over the current merge attrs and over `x_attrs`. With `x_attrs` empty, the inner body never executes and control reaches `return {}`. No positional access to the current attrs list occurs, so there is no missing-index path. This discharges PO1 and PO2.

If `x` is an xarray object or Variable, `x_attrs` contains the attrs dictionaries attached to `x` and its variables/coordinates where available. For each attrs dictionary in the current merge, V1 checks identity first and then checks non-empty dictionary equivalence. If either check succeeds, the callable returns that current attrs dictionary. Since the returned mapping has the same content as an attrs source from `x`, the public content-preservation contract is met. This discharges PO3.

If the current merge has no attrs source from `x`, no identity or non-empty equivalence comparison succeeds. The function reaches `return {}`. This prevents fallback to `cond` or `y` attrs and discharges PO4.

The source diff leaves the `where` signature and `apply_ufunc` call unchanged, and the new logic is guarded by `if keep_attrs is True`. All other `keep_attrs` modes are framed unchanged, discharging PO5.

## Machine-check Commands

These are the commands to run later in an environment with K installed. They were not executed in this task.

```sh
kompile fvk/mini-python-where-attrs.k --backend haskell
kast --backend haskell fvk/xarray-where-attrs-spec.k
kprove fvk/xarray-where-attrs-spec.k
```

Expected result after machine-checking: `kprove` returns `#Top` for the stated claims.

## Test Redundancy

No test removal is recommended in this environment. The proof is constructed, not machine-checked, and the project tests are fixed and hidden for this task. Future public tests that assert the scalar reproducer no longer raises, scalar `x` does not inherit `y` attrs, and xarray `x` preserves attrs would be covered by the claims only after the K commands above are successfully machine-checked.
