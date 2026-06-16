# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Theorem

For every modeled iteration value `M`, the V1 sparse-coding transform path
forwards `M` from the public transform parameter to the lasso backend selected
by the algorithm:

- `lasso_lars` reaches `LassoLars(max_iter=M)`.
- `lasso_cd` continues to reach `Lasso(max_iter=M)`.

## Proof Sketch

1. `SparseCoder`, `DictionaryLearning`, and `MiniBatchDictionaryLearning`
   constructors call `_set_sparse_coding_params(..., transform_max_iter)`.
   `_set_sparse_coding_params` stores that value as `self.transform_max_iter`.
   This discharges PO-1.

2. `SparseCodingMixin.transform` calls `sparse_encode(...,
   max_iter=self.transform_max_iter)`. In the mini-K model this is the
   `transform(A, M) => sparseEncode(A, M, single)` step and emits
   `CalledSparseEncode(M)`. This discharges PO-2.

3. In the single-worker path, `sparse_encode` calls `_sparse_encode(...,
   max_iter=max_iter)`. In the mini-K model this is
   `sparseEncode(A, M, single) => worker(A, M)` and emits `CalledWorker(M)`.
   This discharges PO-5.

4. In the parallel path, `sparse_encode` passes `max_iter=max_iter` into each
   delayed `_sparse_encode` worker. In the mini-K model this is
   `sparseEncode(A, M, parallel) => worker(A, M)` and emits `CalledWorker(M)`.
   This discharges PO-6.

5. In the `lasso_lars` worker branch, `_sparse_encode` constructs
   `LassoLars(..., max_iter=max_iter)`. In the mini-K model this is
   `worker(lasso_lars, M) => .K` and emits `CalledLassoLars(M)`. By
   transitivity with steps 2-4, the public transform and both direct
   `sparse_encode` paths reach `CalledLassoLars(M)`. This discharges PO-3.

6. In the `lasso_cd` worker branch, `_sparse_encode` still constructs
   `Lasso(..., max_iter=max_iter)`. In the mini-K model this is
   `worker(lasso_cd, M) => .K` and emits `CalledLasso(M)`. This discharges
   PO-4.

7. No claim changes the behavior of `lars`, `omp`, or `threshold`; they are
   framed outside this issue-specific proof. This discharges PO-7.

8. Constructor changes append `transform_max_iter` at the end and update all
   internal mixin callsites. The compatibility audit discharges PO-8.

## Claim-to-Source Trace

- C1 `TRANSFORM-LASSO-LARS`: `dict_learning.py:866-879`,
  `dict_learning.py:903-908`, `dict_learning.py:128-131`.
- C2 `SPARSE-ENCODE-LASSO-LARS-SINGLE`: `dict_learning.py:309-318`,
  `dict_learning.py:128-131`.
- C3 `SPARSE-ENCODE-LASSO-LARS-PARALLEL`: `dict_learning.py:325-334`,
  `dict_learning.py:128-131`.
- C4 `LASSO-CD-PRESERVE`: `dict_learning.py:143-145`.

## Machine-check Commands

These were written for later checking and were not executed:

```sh
cd fvk
kompile mini-python-sparse.k --backend haskell
kast --backend haskell sparse-coding-spec.k
kprove sparse-coding-spec.k
```

Expected result after machine checking: `#Top`.

## Test Redundancy Recommendation

No test removal is recommended. The proof is not machine-checked in this
environment, and the task forbids test modification. Future tests worth adding
outside this task would check that `SparseCoder(transform_algorithm='lasso_lars',
transform_max_iter=M)` forwards `M`, and that `sparse_encode(...,
algorithm='lasso_lars', max_iter=M)` forwards `M`.
