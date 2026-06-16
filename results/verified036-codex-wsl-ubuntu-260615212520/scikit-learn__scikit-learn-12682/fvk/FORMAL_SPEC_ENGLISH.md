# Formal Spec in English

The K claims in `sparse-coding-spec.k` are a property-complete abstraction of
the forwarding behavior relevant to the issue. They model calls as events so
the observable under verification is exactly whether the selected backend sees
the intended `max_iter` value.

## Claim C1 - `TRANSFORM-LASSO-LARS`

Starting from a sparse-coding transform with algorithm `lasso_lars` and
iteration value `M`, execution reaches a completed state whose event trace
contains `CalledSparseEncode(M)`, `CalledWorker(M)`, and
`CalledLassoLars(M)`. In source terms, `SparseCodingMixin.transform` forwards
`self.transform_max_iter` to `sparse_encode`, and the `lasso_lars` backend
receives the same value.

## Claim C2 - `SPARSE-ENCODE-LASSO-LARS-SINGLE`

Starting from the single-worker `sparse_encode` path with algorithm
`lasso_lars` and iteration value `M`, execution reaches a completed state
whose event trace contains `CalledWorker(M)` and `CalledLassoLars(M)`.

## Claim C3 - `SPARSE-ENCODE-LASSO-LARS-PARALLEL`

Starting from the parallel `sparse_encode` worker path with algorithm
`lasso_lars` and iteration value `M`, execution reaches a completed state
whose event trace contains `CalledWorker(M)` and `CalledLassoLars(M)`.

## Claim C4 - `LASSO-CD-PRESERVE`

Starting from a sparse-coding transform with algorithm `lasso_cd` and iteration
value `M`, execution reaches a completed state whose event trace contains
`CalledLasso(M)`. This is the preservation obligation for the existing
coordinate-descent backend behavior.

## Frame Conditions

- Algorithms outside `lasso_lars` and `lasso_cd` are not specified to use
  `max_iter` in this issue-specific proof.
- The proof is partial correctness and constructed, not machine-checked.
- The proof abstracts numerical optimization results away; it proves forwarding
  of the iteration parameter, not convergence quality.
