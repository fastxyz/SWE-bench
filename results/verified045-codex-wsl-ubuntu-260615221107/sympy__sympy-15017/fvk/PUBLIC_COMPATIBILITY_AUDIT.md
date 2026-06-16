# Public Compatibility Audit

Status: no compatibility blockers found by static inspection.

## Changed public symbols

- `NDimArray.__len__` is the observable public behavior affected by the V1 fix, but its implementation and signature remain unchanged.
- `ImmutableDenseNDimArray._new`, `MutableDenseNDimArray._new`, `ImmutableSparseNDimArray.__new__`, and `MutableSparseNDimArray.__new__` changed their internal `_loop_size` value for empty shapes. Signatures and return types are unchanged.

## Callers and overrides

- No new arguments, keyword parameters, return shape, or virtual dispatch call were introduced.
- Dense and sparse variants still construct the same classes and store the same `_shape` and rank.
- Public code that expected the issue's buggy `len(rank_zero_array) == 0` behavior is incompatible with the intended fix. The in-repo test asserting that value is marked SUSPECT in `PUBLIC_EVIDENCE_LEDGER.md` and `FINDINGS.md`.

## Producer/consumer shape

- The producer is the constructor cached `_loop_size`.
- The consumer is `NDimArray.__len__`, and sparse iteration also uses `_loop_size`.
- V1 preserves the producer/consumer protocol and changes only the empty-shape value from `0` to `1`.
