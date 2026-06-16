# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` commands were executed.

## Claims proved by construction

The formal claims are in `fvk/array-size-spec.k`:

- C1: immutable dense scalar arrays with shape `()` have length `1`.
- C2: mutable dense scalar arrays with shape `()` have length `1`.
- C3: immutable sparse scalar arrays with shape `()` have length `1`.
- C4: mutable sparse scalar arrays with shape `()` have length `1`.
- C5: a representative nonempty shape keeps product length.

## Proof sketch

1. Constructor execution:
   - `mkDenseImmutable(SHAPE, DATA)`, `mkDenseMutable(SHAPE, DATA)`, `mkSparseImmutable(SHAPE, DATA)`, and `mkSparseMutable(SHAPE, DATA)` each rewrite to `arr(SHAPE, product(SHAPE))`.
   - This models the source constructor assignment to `_loop_size`.

2. Empty-shape product:
   - `product(.Dims)` rewrites to `1`.
   - Therefore each scalar constructor claim reaches `arr(.Dims, 1)`.

3. `len` execution:
   - `len(arr(SHAPE, SIZE))` rewrites to `SIZE`.
   - Instantiating `SIZE = 1` proves C1-C4.

4. Nonempty shape:
   - `product(D : REST)` rewrites to `D * product(REST)`.
   - For `D1 : D2 : .Dims`, symbolic execution gives `D1 * (D2 * 1)`, which simplifies to `D1 * D2`.
   - This proves C5 under the stated nonnegative-dimension side condition.

There are no loops or recursive functions in this reduced audited fragment, so no circularity claim is needed. The proof uses direct symbolic execution and arithmetic simplification only.

## Adequacy gate

- `fvk/INTENT_SPEC.md` states the intent before candidate behavior.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases all claims.
- `fvk/SPEC_AUDIT.md` marks every required behavior as pass and the stale public test as SUSPECT.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no signature or dispatch incompatibility.

The proof therefore supports the conclusion that V1 satisfies the audited intent.

## Reproduce the machine check later

```sh
cd fvk
kompile mini-sympy-array.k --backend haskell
kast --backend haskell array-size-spec.k
kprove array-size-spec.k
```

Expected result after actual execution: `kprove` returns `#Top`.

## Test guidance

Conditioned on future machine-checking, tests asserting scalar rank-0 length is `1` would be subsumed by C1-C4. Tests for indexing behavior, malformed shape/data pairs, reshape, string conversion, and integration across higher-level array operations are not covered by this proof and should be kept or added as ordinary tests. No test files were changed.
