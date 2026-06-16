# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Claims Proved In The Constructed Model

The formal claims are in `fvk/permutation-constructor-spec.k`.

1. `CONSTRUCT-CYCLES-NONDISJOINT`: valid cyclic list input with cross-cycle duplicates returns the left-to-right fold result.
2. `ISSUE-IDENTITY`: `cycles([cycle(0, 1), cycle(0, 1)])` returns `perm([0, 1])`.
3. `ARRAY-DUPLICATES-REJECTED`: array-form duplicate input reaches `error(repeatedArray)`.
4. `CYCLE-FOLD`: the command-level fold over cycles equals the recursive `foldCycles` function.

## Proof Sketch

Array branch:

The constructor classifies a one-level list of integers as array form (`is_cycle` is false). V2 makes the rejecting condition exactly `not is_cycle and has_dups(temp)`. Therefore, for array input with duplicates, the branch reaches the same repeated-elements error as before. This discharges PO-5 and confirms F-3.

Cyclic branch:

The constructor classifies list-of-lists input as cyclic form (`is_cycle` is true). Under V2, the duplicate guard is syntactically false for this branch, so repeated elements across separate cycles cannot trigger the array duplicate error. This discharges PO-2 and resolves F-1.

The remaining cyclic branch initializes `c = Cycle()` and runs `for ci in args: c = c(*ci)`. The mini-K fold models this loop as:

```k
foldCycles(.Cycles, M) => M
foldCycles(C ; CS, M) => foldCycles(CS, composeCycle(M, C))
```

This is a left fold over the input order. The step case consumes the head cycle and composes it with the accumulator before recursing on the tail, so every overlap is handled by composition rather than disjointness validation. This discharges PO-1 and PO-3.

Concrete issue case:

For `[[0, 1], [0, 1]]`, the first cycle maps identity to `swap01`; the second identical cycle composes with `swap01` to `identityMap(1)`. Converting that map to array form yields `0, 1`. This discharges PO-4.

Frame conditions:

The proof does not need to re-prove unrelated `Permutation` behavior. PO-6 is framed because V2 leaves singleton parsing and size extension unchanged. PO-7 is framed because each `ci` is still passed through `Cycle(*ci)`, so per-cycle invalid inputs remain rejected. PO-8 is discharged by the compatibility audit because the public constructor API and storage shape are unchanged.

## Adequacy Gate

The formal English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the intent clauses in `INTENT_SPEC.md`. `SPEC_AUDIT.md` marks every formal item PASS. The only conflicting public evidence is the legacy public test expecting `Permutation([[1], [1, 2]])` to raise; FVK classifies it as SUSPECT because it conflicts with the issue's explicit non-disjoint-cycle intent.

## Machine Check Commands

These commands are emitted for a future environment with K installed. They were not executed here.

```sh
kompile fvk/mini-permutation.k --backend haskell
kast --backend haskell fvk/permutation-constructor-spec.k
kprove fvk/permutation-constructor-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Test Recommendation

Conditioned on machine checking only:

- Add or keep tests for `Permutation([[0, 1], [0, 1]]) == Permutation([0, 1])`.
- Add or keep a non-disjoint, non-cancelling composition test such as `[[1, 2], [2, 3]]` to check order.
- Keep array duplicate rejection tests such as `Permutation([1, 1, 0])`.
- Keep invalid single-cycle tests such as `Cycle(1, 2, 1)`.
- Treat the legacy `Permutation([[1], [1, 2]])` raises test as obsolete under the issue intent.

No test files were modified.
