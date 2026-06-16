# Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level defect that
requires a V2 code edit.

## Rationale

- F-001 and PO-1 through PO-6 show that V1 exposes and forwards the transform
  iteration value through the relevant estimator, `sparse_encode`, and
  `LassoLars` paths.
- F-002 and PO-8 justify keeping the parameter name `transform_max_iter` instead
  of adding a bare `max_iter`.
- F-003 and PO-7 justify not adding generic `algorithm_kwargs`.
- F-004 and PO-8 show that the public API change is additive and source
  compatible.

## Suggested Future Tests

Do not add tests in this task. In a normal development environment, useful
tests would be:

- monkeypatch `LassoLars` and assert `sparse_encode(...,
  algorithm='lasso_lars', max_iter=M)` constructs it with `max_iter=M`;
- monkeypatch `sparse_encode` and assert
  `SparseCoder(..., transform_max_iter=M).transform(X)` passes `max_iter=M`;
- assert `get_params()` exposes `transform_max_iter` on all three estimators
  using `SparseCodingMixin`.

## Commands Not Run

Per task constraints, no tests, Python, or K commands were run. The K commands
are recorded in `PROOF.md` for a future environment.
