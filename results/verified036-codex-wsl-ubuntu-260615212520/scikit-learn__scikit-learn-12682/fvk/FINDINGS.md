# FVK Findings

Status: no blocking findings against V1; V1 stands unchanged.

## F-001 - Original bug is discharged by V1

- Classification: code bug fixed by V1.
- Evidence: `benchmark/PROBLEM.md` reports that `max_iter` was not exposed or
  not forwarded for the lasso backend path.
- Observed pre-fix behavior: `SparseCoder(..., transform_algorithm='lasso_lars')`
  had no public transform-level iteration parameter and `_sparse_encode`
  constructed `LassoLars` without `max_iter`.
- Expected behavior: a user-provided transform iteration value reaches the
  selected lasso backend.
- Proof obligations: PO-1, PO-2, PO-3, PO-5, PO-6.
- V1 status: discharged by `transform_max_iter` plus `LassoLars(max_iter=max_iter)`.

## F-002 - Bare `max_iter` versus `transform_max_iter`

- Classification: resolved API ambiguity.
- Evidence: the issue text says `max_iter`; existing estimator parameters use
  `transform_algorithm`, `transform_alpha`, and `transform_n_nonzero_coefs`.
- Decision: keep V1's `transform_max_iter` name.
- Expected behavior: the new parameter controls transform-time sparse coding
  without conflicting with `DictionaryLearning.max_iter`, which controls the
  fitting loop.
- Proof obligations: PO-1, PO-8.
- V1 status: discharged.

## F-003 - Generic `algorithm_kwargs` not required

- Classification: alternative rejected.
- Evidence: public hints considered kwargs but narrowed the fix to forwarding
  `max_iter` to `LassoLars`.
- Decision: keep V1's explicit parameter rather than adding a generic kwargs
  escape hatch.
- Proof obligations: PO-7, PO-8.
- V1 status: discharged.

## F-004 - Compatibility audit found no source blocker

- Classification: compatibility finding.
- Evidence: constructor parameters were appended, not inserted before existing
  parameters; internal mixin callsites were updated.
- Expected behavior: existing public callsites remain valid.
- Proof obligation: PO-8.
- V1 status: discharged.

## F-005 - Proof and tests were not executed

- Classification: environment limitation, not a code bug.
- Evidence: the task forbids running tests, Python, or K tooling.
- Consequence: proof is constructed, not machine-checked; test removal is not
  recommended.
- Proof obligations: all obligations remain source- and proof-constructed only.
- V1 status: acceptable under task constraints.
