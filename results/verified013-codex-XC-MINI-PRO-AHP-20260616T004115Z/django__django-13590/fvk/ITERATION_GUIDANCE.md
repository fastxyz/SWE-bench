# Iteration Guidance

Status: V1 stands unchanged.

## Decision

The FVK audit did not surface a source-level problem in V1. The existing change
is the minimal repair justified by the public issue:

- it resolves the named tuple constructor arity bug (F1, PO2);
- it keeps recursive element resolution intact (F2, PO3);
- it avoids unpacking plain lists and tuples (F3, PO4);
- it preserves the call protocol and iterable RHS compatibility (F4, PO5).

No additional source edits are recommended.

## Suggested Future Tests

Do not edit tests in this benchmark. For a normal development branch, useful
coverage would be:

- `field__range=Bounds(low, high)` where `Bounds` is a two-field named tuple;
- a named tuple range whose first or second member is an expression-like value;
- regression checks that plain tuple and list range values still work.

## Commands to Machine-Check Later

The following commands are intentionally not run in this session:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell resolve-lookup-value-spec.k
kprove resolve-lookup-value-spec.k
```

Do not remove any tests based on the proof until those commands return `#Top`.

## Next-Iteration Prompt

If this fix is revisited, ask only one clarification: should Django preserve
custom tuple subclasses that are not standard named tuples but also require
positional constructor arguments? The current public issue only justifies the
standard named tuple branch keyed by `_fields`.
