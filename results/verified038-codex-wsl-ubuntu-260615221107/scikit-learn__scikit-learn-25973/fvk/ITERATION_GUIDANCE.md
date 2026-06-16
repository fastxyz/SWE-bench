# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep V1 unchanged.

The audit found that V1 satisfies the intent-derived obligations:

- It normalizes `self.cv` once per fit with `check_cv` (PO-2).
- It relies on `check_cv` to materialize one-shot iterables into reusable stored
  splits (PO-3).
- It passes the checked CV object into every candidate `cross_val_score` call
  (PO-4).
- It preserves the public CV input contract and avoids a new warning or
  generator rejection (PO-1, PO-5, PO-6).

## Recommended Tests If Test Files Were Editable

- Add a nonregression test using `LeaveOneGroupOut().split(X, y, groups)` as the
  `cv` argument to `SequentialFeatureSelector`, matching the public reproduction.
- Add a small custom one-shot iterable test to prove the candidate loop scores
  more than one candidate without exhausting the splits.

The benchmark instructions forbid modifying test files, so no tests were added.

## Machine Verification Follow-Up

Run the recorded commands in `PROOF.md` in an environment with K installed.
Treat test-redundancy recommendations as conditional until `kprove` returns
`#Top`.

## Open Boundaries

- Empty CV iterables should be handled, if desired, at shared model-selection
  validation level rather than in SFS alone.
- Reusing the exact same consumed generator object across multiple independent
  `fit` calls remains outside this issue's intent.
