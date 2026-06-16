# FVK Specification

Status: constructed, not machine-checked.

## Scope

This FVK pass verifies the issue-relevant forwarding behavior in
`repo/sklearn/decomposition/dict_learning.py`:

- `SparseCodingMixin.transform` must pass the estimator-level transform
  iteration limit to `sparse_encode`.
- `sparse_encode` must pass its `max_iter` argument to `_sparse_encode` in both
  single-worker and parallel-worker paths.
- `_sparse_encode` must pass the same value to `LassoLars` for
  `algorithm='lasso_lars'`.
- The existing `Lasso` forwarding for `algorithm='lasso_cd'` must be preserved.

The formal model abstracts numerical optimization away. Its observable is the
backend constructor call and the `max_iter` value supplied to that backend.

## Public Intent Ledger

- E1: "`SparseCoder` doesn't expose `max_iter` for `Lasso`" means the public
  estimator path needs a transform-time iteration control.
- E2: "`max_iter` is ... not passed to `LassoLars`" means the lasso-lars backend
  must receive that value.
- E3: Existing source already passed `max_iter` to coordinate-descent `Lasso`;
  this behavior must remain true.
- E4: Existing public transform controls use the `transform_` prefix, so the
  new estimator parameter is specified as `transform_max_iter`.
- E5: The fix must be additive and minimal, preserving existing public callsites.

Full ledger: `PUBLIC_EVIDENCE_LEDGER.md`.

## Formal Artifacts

- `mini-python-sparse.k`: a minimal K semantics for the sparse-coding forwarding
  fragment. It models transform, sparse_encode, worker dispatch, and backend
  constructor events.
- `sparse-coding-spec.k`: reachability claims for the issue-relevant paths.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of the K claims.
- `SPEC_AUDIT.md`: adequacy gate comparing the formal claims to public intent.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: public API and callsite compatibility check.

## Main Claims

- C1 `TRANSFORM-LASSO-LARS`: a transform using `lasso_lars` and value `M`
  reaches a `CalledLassoLars(M)` backend event.
- C2 `SPARSE-ENCODE-LASSO-LARS-SINGLE`: the single-worker sparse_encode path
  reaches a `CalledLassoLars(M)` backend event.
- C3 `SPARSE-ENCODE-LASSO-LARS-PARALLEL`: the parallel sparse_encode path
  reaches a `CalledLassoLars(M)` backend event.
- C4 `LASSO-CD-PRESERVE`: a transform using `lasso_cd` and value `M` reaches a
  `CalledLasso(M)` backend event.

## Source Mapping

- `transform_max_iter` is stored by `_set_sparse_coding_params` at
  `repo/sklearn/decomposition/dict_learning.py:866`.
- `SparseCodingMixin.transform` passes `max_iter=self.transform_max_iter` to
  `sparse_encode` at `repo/sklearn/decomposition/dict_learning.py:903`.
- `sparse_encode` passes `max_iter=max_iter` to `_sparse_encode` in the
  single-worker path at `repo/sklearn/decomposition/dict_learning.py:310`.
- `sparse_encode` passes `max_iter=max_iter` in the parallel-worker path at
  `repo/sklearn/decomposition/dict_learning.py:325`.
- `_sparse_encode` passes `max_iter=max_iter` to `LassoLars` at
  `repo/sklearn/decomposition/dict_learning.py:128`.
- `_sparse_encode` still passes `max_iter=max_iter` to `Lasso` at
  `repo/sklearn/decomposition/dict_learning.py:143`.

## Machine-check Commands

These commands are required to machine-check the constructed proof, but were
not run in this environment:

```sh
cd fvk
kompile mini-python-sparse.k --backend haskell
kast --backend haskell sparse-coding-spec.k
kprove sparse-coding-spec.k
```

Expected machine-check result after the semantics parses and the claims
discharge: `#Top`.
