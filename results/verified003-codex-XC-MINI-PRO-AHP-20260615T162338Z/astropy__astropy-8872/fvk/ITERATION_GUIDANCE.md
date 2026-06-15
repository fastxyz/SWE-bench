# Iteration Guidance

Status: V1 stands unchanged after FVK audit.

## Decision

Do not make a V2 source edit.

Rationale:

- `F-001` identifies the original code bug and shows that V1 removed the
  faulty `float32` castability proxy.
- `F-002` confirms the V1 predicate matches the public family obligation to
  allow every inexact dtype.
- `F-003` confirms V1 preserves explicit dtype, integer/bool/object default
  coercion, and structured dtype behavior.
- `F-004` confirms no public compatibility break.
- `PO-1` through `PO-9` are discharged by V1 plus unchanged source behavior.

## Suggested Next Tests

Do not edit test files in this benchmark. In a normal project pass, add focused
tests for:

- scalar `np.float16` multiplied by a unit;
- `np.float16` arrays passed directly to `Quantity`;
- copying an existing `float16` `Quantity`;
- unchanged frame cases for integer, bool, object Decimal, explicit dtype, and
  structured dtype.

## Machine Verification

The FVK proof is constructed, not machine-checked. To upgrade confidence, run:

```sh
kompile fvk/mini-quantity.k --backend haskell
kast --backend haskell fvk/quantity-dtype-spec.k
kprove fvk/quantity-dtype-spec.k
```

Expected result: `kprove` returns `#Top` for all claims.

## If a Future Audit Expands Scope

A future pass could factor the duplicated predicate into a private helper for
readability, but FVK does not require that change. The current two-line V1 patch
is minimal and keeps the public surface unchanged.
