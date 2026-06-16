# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The audit found the V1 edit is the minimal source change that satisfies the
public issue:

```python
make_hashable(self.through_fields)
```

in `ManyToManyRel.identity`.

## Source Changes for This Iteration

No V2 source edits are required. The V1 source diff remains:

```diff
 return super().identity + (
     self.through,
-    self.through_fields,
+    make_hashable(self.through_fields),
     self.db_constraint,
 )
```

## Rejected Changes

1. Do not convert `self.through_fields` in `ManyToManyRel.__init__`.
   Trace: F-003 and PO-3.
2. Do not wrap all of `self.identity` in `make_hashable()` inside
   `ForeignObjectRel.__hash__()`.
   Trace: F-004 and PO-4.
3. Do not modify tests in this benchmark task.
   Trace: PO-6.

## Suggested Follow-Up Tests

If tests were being added outside this benchmark's hidden-suite constraint, the
targeted regression should construct a `ManyToManyField` with an explicit
through model and `through_fields=["child", "parent"]`, then exercise model
checks on a proxy model path that hashes reverse relation objects.

The essential assertion is that model checks complete without
`TypeError: unhashable type: 'list'`.

## Verification Commands Not Run

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/many-to-many-rel-spec.k
kprove fvk/many-to-many-rel-spec.k --backend haskell
```

Keep the proof labeled "constructed, not machine-checked" until these commands
return `#Top` in an environment with K tooling.
