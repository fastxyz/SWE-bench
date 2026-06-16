# Iteration Guidance

Status: V2 code is the recommended patch under the FVK artifacts.

## Code Decision

No additional semantic repair is needed beyond V1. V2 makes the proof-relevant duplicate guard explicit and documents the reported case:

- Keep cyclic list input out of the array duplicate rejection branch.
- Keep left-to-right folding through the existing `Cycle` machinery.
- Keep array duplicate rejection and per-cycle validation unchanged.

## Future Machine Check

Run these commands in an environment with K installed:

```sh
kompile fvk/mini-permutation.k --backend haskell
kast --backend haskell fvk/permutation-constructor-spec.k
kprove fvk/permutation-constructor-spec.k
```

If K reports parser or sort issues, repair the mini-K artifact without changing the source-code conclusion unless the repaired claims change an obligation in `PROOF_OBLIGATIONS.md`.

## Suggested Test Updates

Do not modify tests in this benchmark run. For upstream development, add or adjust tests to cover:

- `Permutation([[0, 1], [0, 1]])` returns identity.
- A non-disjoint product with distinct cycles uses left-to-right order.
- Array-form duplicates still raise.
- Duplicates within a single cycle still raise.
- Singletons and `size` still behave as documented.

The legacy public test expecting `Permutation([[1], [1, 2]])` to raise should be reconsidered because it conflicts with the issue intent.

## Residual Risk

The proof is partial and constructed, not machine-checked. It covers the constructor branch involved in this issue, not the full SymPy permutation module. Behavior outside cyclic-list construction remains covered by the normal project test suite, not by this FVK proof.
