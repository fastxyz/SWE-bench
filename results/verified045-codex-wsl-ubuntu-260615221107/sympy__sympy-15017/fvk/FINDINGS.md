# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and static inspection only.

## F1: Pre-V1 rank-0 scalar length was wrong

- Classification: code bug addressed by V1.
- Input: `sympy.Array(3)`, represented by `ImmutableDenseNDimArray(3)` with shape `()`.
- Observed before V1: `_loop_size` was set to `0`, so `len(a)` returned `0`.
- Expected: `len(a)` returns `1`, matching the issue statement and the one scalar element in the iterator example.
- Evidence: ledger E1-E5.
- Proof obligations: PO1, PO2, PO3.
- Resolution: V1 changes the constructor cached `_loop_size` to use `functools.reduce(..., shape, 1)`, so the empty shape now has size `1`.

## F2: Legacy public test is SUSPECT

- Classification: stale public-test evidence that conflicts with issue intent.
- Input: `ImmutableDenseNDimArray(x)`.
- Observed public test expectation: `assert len(rank_zero_array) == 0`.
- Expected by public issue intent: length should be `1`.
- Evidence: ledger E7 conflicts with E1-E4.
- Proof obligations: PO6.
- Resolution: do not preserve the legacy assertion as a frame condition. Test files are not modified in this task.

## F3: V1 correctly fixes the shared source of `__len__`

- Classification: confirmed source-level repair.
- Input class: well-formed dense/sparse mutable/immutable arrays.
- Observed in V1: every constructor path now computes `_loop_size` as `product(shape)` with empty product `1`; `NDimArray.__len__` still returns `_loop_size`.
- Expected: scalar rank-0 arrays return length `1`, and nonempty shapes continue to return the product of dimensions.
- Evidence: ledger E5, E6, E8, E9.
- Proof obligations: PO1-PO5.
- Resolution: no additional source edit is justified by this FVK pass.

## F4: No public compatibility blocker found

- Classification: compatibility audit pass.
- Input class: public calls to `len(array)` and existing constructors.
- Observed in V1: signatures and dispatch patterns are unchanged.
- Expected: public APIs remain callable as before, with corrected scalar length.
- Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Proof obligations: PO5.
- Resolution: V1 stands.

## Proof-derived findings from `/verify`

No proof-derived code bug remains in the audited behavior. The constructed proof depends on machine-checking the emitted K artifacts before claiming a machine-verified result. Test removal, if any, is conditioned on that future machine check.
