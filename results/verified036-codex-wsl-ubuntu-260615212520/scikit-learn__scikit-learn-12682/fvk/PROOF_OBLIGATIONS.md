# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Public transform iteration control

- Obligation: each estimator using `SparseCodingMixin.transform` must expose a
  transform-time max-iteration parameter.
- Evidence: issue says `SparseCoder` does not expose `max_iter`; existing
  transform controls use `transform_` names.
- Source discharge: `transform_max_iter=1000` added to `SparseCoder`,
  `DictionaryLearning`, and `MiniBatchDictionaryLearning`; `_set_sparse_coding_params`
  stores it.
- Result: DISCHARGED.

## PO-2 - Estimator-to-sparse_encode forwarding

- Obligation: `SparseCodingMixin.transform` must call `sparse_encode` with
  `max_iter=self.transform_max_iter`.
- Source discharge: `dict_learning.py:903-908`.
- Formal claim: C1 `TRANSFORM-LASSO-LARS`.
- Result: DISCHARGED.

## PO-3 - LassoLars forwarding

- Obligation: `_sparse_encode(..., algorithm='lasso_lars', max_iter=M)` must
  construct `LassoLars(..., max_iter=M)`.
- Source discharge: `dict_learning.py:128-131`.
- Formal claims: C1, C2, C3.
- Result: DISCHARGED.

## PO-4 - Existing Lasso forwarding preserved

- Obligation: `_sparse_encode(..., algorithm='lasso_cd', max_iter=M)` must keep
  constructing `Lasso(..., max_iter=M)`.
- Source discharge: `dict_learning.py:143-145`.
- Formal claim: C4 `LASSO-CD-PRESERVE`.
- Result: DISCHARGED.

## PO-5 - Direct sparse_encode single-worker path

- Obligation: `sparse_encode(..., max_iter=M)` must pass `M` to `_sparse_encode`
  when it takes the single-worker path.
- Source discharge: `dict_learning.py:309-318`.
- Formal claim: C2.
- Result: DISCHARGED.

## PO-6 - Direct sparse_encode parallel path

- Obligation: `sparse_encode(..., max_iter=M)` must pass `M` to each
  `_sparse_encode` worker when it takes the parallel path.
- Source discharge: `dict_learning.py:325-334`.
- Formal claim: C3.
- Result: DISCHARGED.

## PO-7 - Non-target algorithms framed

- Obligation: algorithms outside `lasso_lars` and `lasso_cd` should not receive
  new max-iteration behavior from this issue-specific fix.
- Source discharge: V1 changes only the lasso-lars constructor and the shared
  forwarding of an already-existing `sparse_encode` argument.
- Result: DISCHARGED.

## PO-8 - Public compatibility

- Obligation: existing public constructor and callsite compatibility must be
  preserved.
- Source discharge: new public constructor parameters are appended; no existing
  parameter is removed or renamed; internal mixin callsites are updated.
- Audit: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Result: DISCHARGED.

## Residual Non-obligations

- Numerical convergence is not proved. The public issue requires the ability to
  set and forward the iteration control.
- Invalid `max_iter` validation is not changed. This proof treats `M` as a
  value to be forwarded and relies on the underlying estimators for validation.
