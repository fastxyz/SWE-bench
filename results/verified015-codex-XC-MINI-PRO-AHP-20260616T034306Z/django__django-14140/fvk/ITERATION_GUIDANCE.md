# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit production code in V2. The V1 source change satisfies the
intent-derived obligations PO-1 through PO-5 and leaves only the explicit
non-domain boundary PO-6.

## Why V1 Stands

1. F-001 is resolved by PO-2: conditional children no longer enter the branch
   that indexes lookup pairs.
2. F-002 is preserved by PO-1: ordinary one-lookup `Q` objects still return the
   kwargs format required by public evidence.
3. F-003 is preserved by PO-3: nested `Q` children remain positional because
   `Q.conditional` is true.
4. PO-5 confirms that conditional children now routed through the positional
   path retain connector and negation metadata.
5. F-004 is a scope boundary, not a failing proof obligation, because the public
   hint explicitly says conditional-expression handling is sufficient.

## Rejected V2 Changes

Removing the single-child kwargs special case:

- Rejected because it would violate E1 and E5 and fail PO-1.

Adding a strict length-two tuple check before the kwargs branch:

- Rejected for this task because it would broaden the patch beyond the
  conditional-expression obligation and potentially change currently accepted
  subscriptable lookup-pair inputs. F-004 records the unsupported input boundary
  instead.

Special-casing `Exists` by class name:

- Rejected because E7 and E8 show Django already exposes a general
  `conditional` protocol. PO-2 is intentionally phrased over all supported
  conditional expression children.

## Next Tests To Add Outside This Benchmark

Tests should not be modified in this task, but a future conventional test patch
should include:

- direct deconstruction of `Q(Exists(...))`
- deconstruction of negated `Q(Exists(...))`
- preservation of existing `Q(x=1)` kwargs deconstruction
- preservation of nested `Q` positional deconstruction

## Commands Not Run

The benchmark forbids test execution and K tooling. The formal commands remain
documentation only:

```sh
kompile fvk/mini-q-deconstruct.k --backend haskell
kast --backend haskell fvk/q-deconstruct-spec.k
kprove fvk/q-deconstruct-spec.k
```

