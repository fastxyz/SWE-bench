# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Code Decision

Keep V1 unchanged.

Reasoning:

- `F-001` and `F-002` identify the only intent-violating behavior relevant to
  the issue: incomplete credentials triggered lookup/hash/password work.
- `PO-001` and `PO-002` show V1 places the guard after username normalization
  and before all expensive side effects.
- `F-003` and `F-004` show the complete-credential behavior remains intact,
  backed by `PO-003` through `PO-006`.
- `PO-007` shows no public signature or subclass dispatch compatibility issue.

No FVK finding requires a V2 source edit.

## If Another Iteration Were Requested

- Add public tests for the incomplete-credential no-query/no-hash behavior:
  normalized username missing, password missing, and credentials intended for a
  different backend.
- Keep complete-credential tests for successful authentication, bad passwords,
  inactive users, custom `USERNAME_FIELD`, and nonexistent-user timing
  mitigation.
- Machine-check the K artifacts with the commands in `PROOF.md`; keep all test
  removal recommendations conditional on a `kprove` result of `#Top`.

## Residual Risks

- The formal model is event-abstract and does not prove the Django ORM,
  password hashing, or auth dispatcher implementation.
- The proof is partial correctness only. It assumes lookup, hasher, and user
  predicate calls return or raise in the modeled way.
- The proof is constructed, not machine-checked, because this task forbids
  running K tooling.

