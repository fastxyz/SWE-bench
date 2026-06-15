# Constructed Proof

Constructed, not machine-checked. No K tooling was run.

## Machine-check commands not executed

The task forbids running K framework tooling. These are the commands a later human or CI job would run:

```sh
cd fvk
kompile mini-bulk-create.k --backend haskell
kast --backend haskell bulk-create-batching-spec.k
kprove bulk-create-batching-spec.k
```

Expected machine-checked success condition: `kprove` returns `#Top` for all claims.

## Proof sketch

### Effective batch size

The V1 source computes:

```python
max_batch_size = max(ops.bulk_batch_size(fields, objs), 1)
batch_size = min(batch_size, max_batch_size) if batch_size else max_batch_size
```

Let `C = max(ops.bulk_batch_size(fields, objs), 1)`.

- If no user batch size is supplied, Python truthiness takes the `else` branch and assigns `batch_size = C`.
- If a positive user batch size `U` is supplied and `U <= C`, `min(U, C) = U`.
- If a positive user batch size `U` is supplied and `U > C`, `min(U, C) = C`.

Therefore the effective batch size is always `<= C`, and it equals the issue's requested min logic.

### Batch generation

The loop uses:

```python
for item in [objs[i:i + batch_size] for i in range(0, len(objs), batch_size)]:
```

Given `batch_size = B >= 1`, `range(0, N, B)` produces offsets `0, B, 2B, ...` less than `N`. Each slice length is:

- `B` for every full slice where `i + B <= N`.
- `N - i` for the final partial slice, where `0 < N - i <= B`.

Since PO2 establishes `B <= C`, every emitted slice length is `<= C`. The slices are contiguous and non-overlapping, so their lengths sum to `N`.

### Pre-fix counterexample

Take `N = 10`, backend cap `C = 3`, and explicit user batch `U = 5`.

- V0 effective batch size: `5`.
- V0 first emitted slice length: `5`, violating `<= C`.
- V1 effective batch size: `min(5, 3) = 3`.
- V1 emitted slice lengths: `3, 3, 3, 1`, all `<= 3` and summing to `10`.

This counterexample localizes the issue to the effective-batch calculation, and V1 removes it.

## Proof obligations status

- PO1: discharged by the intent ledger and adequacy audit.
- PO2: discharged by the case split over absent user batch, `0 < U <= C`, and `U > C`.
- PO3: discharged by the slice-length argument and `B <= C`.
- PO4: discharged by contiguous range slicing with positive step.
- PO5: discharged by the edit placement inside `_batched_insert()`.
- PO6: discharged by compatibility inspection.
- PO7: discharged by the existing positive explicit-batch assertion.

## Residual risk

This proof is partial correctness for batching arithmetic only. It does not prove termination of database calls, SQL execution, transaction semantics, backend implementation correctness, or object state mutation. Because the proof is constructed but not machine-checked, no test removal is recommended.
