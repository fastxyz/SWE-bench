# Iteration Guidance

Status: V2 source refactor applied.

## Decision

Do not leave V1 exactly as written. V1 fixed the reported crash, but FVK Finding
F2 showed that the proof of alignment depended on multiple separately written
non-`None` filters. V2 centralizes that active-estimator list in
`non_none_estimators` and uses it for:

- sample-weight support checking;
- fitting/cloning;
- `named_estimators_` construction.

## Next Actions

1. Keep the V2 source change.
2. Do not modify tests in this benchmark.
3. When an execution environment is available, run the normal scikit-learn
   voting tests and add/expect coverage for weighted fit after
   `set_params(name=None)`.
4. When K is available, run the emitted commands in `PROOF.md` before treating
   any routing tests as redundant.

## Open Questions

No user-intent ambiguity remains for the reported issue. The exact contents of
`named_estimators_` for dropped estimators were not explicitly described by a
dedicated test, but the public docs say it accesses fitted estimators; this
supports active-only aligned mapping rather than including dropped names.
