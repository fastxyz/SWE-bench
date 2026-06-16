# Constructed Proof

Status: constructed, not machine-checked. No K command was run in this session.

## What Is Proved

For every finite list `XS` of hashable keys represented in the model,
`list(reversed(OrderedSet(XS)))` reaches `reverseList(uniqueFirst(XS))`.
In Python terms, reverse iteration over an `OrderedSet` yields the set's
distinct elements in the opposite of insertion order.

## Proof Sketch

1. Constructor modeling: `OrderedSet(XS)` rewrites to `os(dictFromKeys(XS))`.
2. Dictionary construction: `dictFromKeys(XS)` rewrites to `uniqueFirst(XS)`,
   matching `dict.fromkeys()` as used by `OrderedSet.__init__()`.
3. Method modeling: `reversed(os(KS))` rewrites to `dictReversedKeys(KS)`.
4. Dictionary reverse iteration: `dictReversedKeys(KS)` rewrites to
   `reverseList(KS)`.
5. Composition by transitivity gives
   `list(reversed(OrderedSet(XS))) => reverseList(uniqueFirst(XS))`.
6. The rewrite rules for `reverseList()` and `uniqueFirst()` handle empty and
   duplicate cases structurally. The concrete witness claim
   `[1, 2, 1] -> [2, 1]` distinguishes set-content reversal from raw-input
   reversal.

No loop circularity is needed because the audited method has no loop. The
recursive helper equations in the mini semantics are structural definitions of
the abstraction functions used to express the postcondition.

## Proof Obligations

The constructed proof discharges PO-001 through PO-007 in
`fvk/PROOF_OBLIGATIONS.md`. No obligation requires a source change beyond V1.

## Commands To Machine-Check Later

These commands are recorded only; they were not executed.

```sh
cd fvk
kompile mini-python-orderedset.k --backend haskell
kast --backend haskell orderedset-reversed-spec.k
kprove orderedset-reversed-spec.k
```

Expected result after a successful machine check: `kprove` reduces the claims to
`#Top`.

## Test Redundancy Guidance

Do not remove tests based on this constructed proof alone. If the K commands
later machine-check successfully, point tests asserting ordinary reverse-order
examples such as `list(reversed(OrderedSet([1, 2, 3]))) == [3, 2, 1]` would be
subsumed by K-002. Boundary and integration tests should still be kept unless
the project maintainers explicitly decide otherwise.

## Residual Risk

This is a partial, issue-scoped proof over a mini Python model. It relies on the
adequacy of modeling the backing dictionary by its key list and on the local
runtime side condition that Python `>=3.8` supports dictionary reverse iteration.
The proof is constructed, not machine-checked.
