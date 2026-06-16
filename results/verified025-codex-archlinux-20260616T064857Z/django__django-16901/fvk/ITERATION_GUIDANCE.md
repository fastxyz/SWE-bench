# ITERATION GUIDANCE

Status: constructed, not machine-checked.

## Source Decision

Keep V1 unchanged.

Rationale:

- FVK-F1 and FVK-F2 show V1 changes the fallback from exactly-one semantics to
  odd-parity semantics for the reported case and the full repeated-true family.
- `PO-XOR-PARITY`, `PO-MOD-PARITY`, and `PO-OR-REDUNDANCY` show the V1 formula
  is equivalent to the public intent.
- `PO-NEGATION` shows the existing negation path remains correct.
- `PO-COMPATIBILITY` shows no public API or caller compatibility issue was
  introduced.

## No Additional Code Changes

Do not remove the retained `OR` wrapper in this pass. Although redundant under
parity, it preserves the previous fallback shape and short-circuit behavior.
This is documented in FVK-F4 and `PO-OR-REDUNDANCY`.

Do not add an initializer to the internal `reduce()` in this pass. Empty internal
`WhereNode(connector=XOR)` construction is outside the public issue path, as
documented in FVK-F3 and `PO-DOMAIN`.

## Suggested Future Tests

No test files were modified, per task constraints.

If tests are added in a separate allowed pass, target non-native logical XOR
fallback behavior for:

- three true predicates returning true;
- four true predicates returning false;
- five true predicates returning true;
- negated three-operand XOR returning false.

Keep existing integration tests until the K commands in `fvk/PROOF.md` are run
and return `#Top`.

## Machine Check Follow-Up

The constructed proof can be checked later with:

```sh
kompile fvk/mini-xor-fallback.k --backend haskell
kast --backend haskell fvk/xor-fallback-spec.k
kprove fvk/xor-fallback-spec.k
```
