# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The audit discharged the obligations required by the issue:

- PO1 proves all marked bases are represented during class mark lookup.
- PO2 and PO3 justify the `consider_mro=False` storage path.
- PO4 and PO5 preserve non-class and invalid-mark behavior.
- PO7 confirms the helper signature change is backwards-compatible for existing
  callsites.

The audit did not use the ambiguous PO6 order policy to justify success.

## Next code iteration

No production code change is recommended for this task.

Future work, if maintainers want to narrow behavior beyond the issue:

1. Decide whether inherited class marks should be yielded in Python MRO order,
   reverse-MRO order, or documented as order-unspecified for sibling bases.
2. If descriptor-based `pytestmark` on metaclasses is intended public behavior,
   design a separate protocol for distinguishing direct descriptor-provided
   marks from inherited descriptor-provided marks.
3. Add public tests for multiple inheritance membership. Add order-sensitive
   tests only after item 1 is resolved.

## Verification commands

The following commands are recorded for later machine checking and were not run:

```sh
kompile fvk/mini-python-marks.k --backend haskell
kast --backend haskell fvk/mark-mro-spec.k
kprove fvk/mark-mro-spec.k
```

Expected result after a real K run: `#Top` for the modeled claims. Until then,
the proof remains constructed, not machine-checked.
