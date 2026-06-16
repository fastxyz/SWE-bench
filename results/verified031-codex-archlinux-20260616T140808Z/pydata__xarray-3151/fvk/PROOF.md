# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Theorem

For the validation step in `combine_by_coords`, V1 is partially correct with
respect to the public intent:

1. identical coordinate dimensions that do not vary between datasets are not
   rejected solely for being non-monotonic;
2. dimensions that do vary and are selected for concatenation are still
   rejected if their combined global index is neither monotonic increasing nor
   monotonic decreasing.

## Proof Sketch

1. In `_infer_concat_order_from_coords`, each dimension coordinate is inspected
   across the datasets in a same-variable group.

2. If all indexes for a dimension equal the first index, the condition
   `not all(index.equals(indexes[0]) for index in indexes[1:])` is false. The
   branch containing `concat_dims.append(dim)` is skipped. Therefore equal-index
   dimensions are not members of `concat_dims`.

3. If a dimension's indexes are not all equal, the branch appends that dimension
   to `concat_dims` after confirming each per-dataset index is monotonic
   increasing or monotonic decreasing. That dimension is a concat dimension for
   the later `_combine_nd` step.

4. V1 changes the final validation loop from `for dim in concatenated.dims` to
   `for dim in concat_dims`. By ordinary loop semantics, only members of
   `concat_dims` can reach the body of that validation loop.

5. From steps 2 and 4, a bystander dimension whose indexes are identical across
   all datasets cannot reach the final monotonicity check. Therefore the
   reported `y = ['a', 'c', 'b']` coordinate cannot trigger the final
   `ValueError` branch merely because it is non-monotonic.

6. From steps 3 and 4, a dimension selected for concatenation still reaches the
   validation body. The body still raises the same `ValueError` when the
   combined index is neither monotonic increasing nor monotonic decreasing.
   Therefore the impossible-ordering behavior for a real concat dimension, such
   as `x`, is preserved.

7. The diff does not touch public signatures, grouping, `_combine_nd`, `concat`,
   `merge`, or tests. The proof is therefore scoped to the validation policy
   and does not claim broader behavior changes.

## Reported Example Instantiation

For the issue's input:

- `x` varies between datasets, so `x in concat_dims`;
- `y` has equal indexes across datasets, so `y not in concat_dims`;
- the V1 validation loop binds `dim = x` only;
- the non-monotonicity of `y` is not inspected by the final validation loop;
- `combine_by_coords` is no longer expected to raise the reported
  `ValueError` along `y`.

## Regression Instantiation

For the public impossible-ordering example:

- `x` varies between datasets, so `x in concat_dims`;
- the V1 validation loop binds `dim = x`;
- the unchanged branch raises if the concatenated `x` index is not globally
  monotonic;
- the required `ValueError` along `x` is preserved.

## Adequacy

The proof obligations match the intent ledger:

- `SPEC.md` I1 and I2 require ignored coordinate dimensions to remain ignored.
  PO-1 through PO-3 prove that V1 implements this by validating only
  `concat_dims`.
- `SPEC.md` I3 and I4 require impossible ordering along real concat dimensions
  to keep failing. PO-4 proves that the error branch remains active for
  `concat_dims`.
- `SPEC.md` C4 requires public compatibility. PO-5 proves the API and call
  shapes are untouched.

No proof obligation depends on hidden tests, benchmark verdicts, internet
access, or original upstream fixes.

## Non-Executed Machine Check

The task forbids K tooling. The formal commands that would be used after
materializing the abstract claim schema are:

```sh
kompile fvk/mini-xarray-combine.k --backend haskell
kast --backend haskell fvk/combine-by-coords-spec.k
kprove fvk/combine-by-coords-spec.k
```

Expected outcome after materialization and a successful machine check:
`kprove` returns `#Top` for the bystander-frame and concat-dimension-validation
claims.

## Residual Risk

This is a partial-correctness proof over the validation logic. It does not
prove termination, performance, or the full behavior of xarray concat/merge. No
test-redundancy recommendation is made because the proof was not
machine-checked and the task forbids executing tests.
