# PROOF

Status: constructed, not machine-checked.

## Machine-Check Commands

These commands were not run in this session:

```sh
kompile fvk/mini-xor-fallback.k --backend haskell
kast --backend haskell fvk/xor-fallback-spec.k
kprove fvk/xor-fallback-spec.k
```

Expected machine-check result after a successful proof: `#Top`.

## Claims

The formal core in `fvk/xor-fallback-spec.k` states:

- `fallback(BS) => oddParity(BS)` for non-empty child lists.
- `negFallback(BS) => notBool oddParity(BS)` for negated XOR.
- the pre-fix `exactlyOne` predicate disagrees with parity on
  `[true, true, true]`.

## Constructed Proof Sketch

Let `B` be a non-empty list of child truth values and let
`k = truth_count(B)`.

1. By `PO-CASE-COUNT`, each child contributes either `0` or `1`.
2. By `PO-SUM`, the fallback sum is exactly `k`.
3. By `PO-MOD-PARITY`, `k % 2 == 1` iff `k` is odd.
4. By `PO-OR-REDUNDANCY`, `k % 2 == 1` implies at least one child is true, so
   the retained `OR` side is true whenever the modulo side is true.
5. If the modulo side is false, the conjunction is false. If the modulo side is
   true, the OR side is also true and the conjunction is true.
6. Therefore the synthesized fallback is equivalent to `odd_parity(B)`.
7. By `PO-NEGATION`, the existing `self.negated` path applies `NOT` to that
   equivalent predicate, so negated XOR is equivalent to `NOT odd_parity(B)`.

For the reported counterexample `B = [true, true, true]`, `k = 3`, so:

```text
pre-fix exactlyOne(B) = (3 == 1) = false
V1 oddParity(B) = (3 % 2 == 1) = true
```

This proves the V1 source change repairs the described defect for the reported
case and for the full odd/even family described by the issue.

## Adequacy

The proof proves odd truth-count parity, not merely the current implementation's
behavior. That matches the public issue text and the expected sequence
`1, 0, 1, 0, 1`.

The proof does not rely on hidden tests, upstream fixes, external benchmark
signals, or execution results.

## Residual Risk

The formal model abstracts a compiled SQL child predicate to the boolean observed
by `CASE WHEN child THEN 1 ELSE 0`. This is adequate for the changed expression
because V1 leaves child compilation and `CASE` generation unchanged.

The proof is constructed, not machine-checked. Test removal is not recommended
unless the commands above are run and return `#Top`.

No tests, Python code, or K tooling were run.
