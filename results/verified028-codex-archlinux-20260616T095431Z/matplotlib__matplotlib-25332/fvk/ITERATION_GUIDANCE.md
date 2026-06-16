# FVK Iteration Guidance

Status: V1 stands unchanged.

## Code decision

No additional source edit is justified by the FVK audit.

Reason:

- `FINDINGS.md` F1 identifies the actual issue symptom and root cause: pickle saw raw weakrefs inside `Grouper._mapping`.
- `PROOF_OBLIGATIONS.md` O1 is satisfied by V1's `__getstate__()` returning `list(self)`.
- `FINDINGS.md` F2 rejects the narrower alternative of dropping `_align_label_groups`; `PROOF_OBLIGATIONS.md` O2 and O3 are satisfied by V1's `__setstate__()` rebuilding groups with `join(*group)`.
- `PROOF_OBLIGATIONS.md` O5 confirms V1 does not change existing public method signatures or non-pickle `Grouper` behavior.

## Deferred or rejected changes

1. Do not special-case `Figure.__getstate__()` to delete `_align_label_groups`.
   Reason: this would satisfy only `pickle.dumps(fig)` and violate the persistence obligation in `SPEC.md` E3.

2. Do not add defensive handling for arbitrary malformed `__setstate__()` input.
   Reason: `FINDINGS.md` F4 records that the proven domain is state emitted by `__getstate__()`, which is the pickle path required by the issue.

3. Do not replace `Grouper` weakrefs with strong references.
   Reason: this would change the container's memory-management semantics and is not required by any proof obligation.

## Recommended future tests

Do not modify tests in this benchmark task. In a normal development pass, add focused tests for:

- Pickling a figure after `fig.align_labels()`.
- Unpickling that figure and verifying the x/y alignment group relationships still exist.
- Optional direct `Grouper` round-trip where grouped objects are also held strongly outside the grouper.

## Residual risk

The proof is constructed, not machine-checked. The K files are abstraction sketches over the live partition behavior of `Grouper`, not a full Python semantics. Keep integration tests and existing pickle tests until a real K run or ordinary test run confirms the patch.

