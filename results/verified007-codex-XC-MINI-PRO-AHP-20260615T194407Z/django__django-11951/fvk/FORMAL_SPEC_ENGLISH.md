# Formal Spec English

Constructed, not machine-checked.

- Claim `effectiveBatch(noBatch, C) => C` says: for any compatible cap `C >= 1`, omitting `batch_size` uses the compatible cap.
- Claim `effectiveBatch(userBatch(U), C) => U` under `0 < U <= C` says: a positive explicit batch size smaller than or equal to the compatible cap is preserved.
- Claim `effectiveBatch(userBatch(U), C) => C` under `U > C >= 1` says: a positive explicit batch size larger than the compatible cap is reduced to the cap.
- Claim `batchLengths(N, effectiveBatch(noBatch, C))` says: for `N >= 0`, the generated insert batch lengths cover exactly `N` objects and every emitted length is at most `C`.
- Claim `batchLengths(N, effectiveBatch(userBatch(U), C))` says: for `N >= 0`, `C >= 1`, and positive explicit `U`, the generated insert batch lengths cover exactly `N` objects and every emitted length is at most `C`.
- Frame condition: the formal model only constrains effective batch size and emitted slice lengths. It does not change or specify `ignore_conflicts`, returning-row handling, transaction behavior, object state updates, or the database `_insert()` result values.
