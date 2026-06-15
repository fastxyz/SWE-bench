# Proof Obligations

Constructed, not machine-checked.

## PO1 - Intent adequacy

The formal model must encode the public issue intent rather than V1 behavior alone.

- Source: E1, E2, E3, E4.
- Obligation: explicit `batch_size` values larger than the backend-compatible cap must be clamped.
- Status: discharged by `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.

## PO2 - Effective-batch clamp

For all compatible caps `C >= 1`:

- `effectiveBatch(noBatch, C) = C`.
- If `0 < U <= C`, `effectiveBatch(userBatch(U), C) = U`.
- If `U > C`, `effectiveBatch(userBatch(U), C) = C`.

Status: encoded by the first three claims in `bulk-create-batching-spec.k`; V1 source matches these cases.

## PO3 - Emitted batch lengths obey the cap

For all object counts `N >= 0`, compatible caps `C >= 1`, and positive explicit user sizes `U`, every emitted batch length from `range(0, N, effective_batch)` is `<= C`.

Status: encoded by the two `batchLengths(... effectiveBatch(...))` claims and `allLeq()`.

## PO4 - Emitted batches cover exactly the input object count

For all `N >= 0`, the generated batch lengths sum to `N`.

Status: encoded by `sumList(?Batches) ==Int N` in the batch-length claims. This ensures clamping does not drop or duplicate objects.

## PO5 - Correct placement of cap calculation

The backend cap must be calculated using the actual `fields` passed to `_batched_insert()`.

Status: discharged by V1 placement. The edit is inside `_batched_insert()`, after `fields` is known for each `bulk_create()` path.

## PO6 - Frame and compatibility obligations

The patch must preserve:

- `bulk_create()` and `_batched_insert()` signatures.
- `ignore_conflicts` support validation.
- returning-row branch behavior.
- `_insert()` call shape except for the size of `item`.
- object state updates after `_batched_insert()` returns.

Status: discharged by source inspection and `PUBLIC_COMPATIBILITY_AUDIT.md`; no further code change required.

## PO7 - Domain and validation obligations

The proof domain assumes explicit `batch_size` is positive when supplied, matching the existing `bulk_create()` assertion.

Status: discharged by existing code. No public issue evidence requires changing invalid `batch_size` handling in this pass.
