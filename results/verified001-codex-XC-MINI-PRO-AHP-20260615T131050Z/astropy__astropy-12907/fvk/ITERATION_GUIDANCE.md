# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit confirms that the source edit is exactly the
PO-3 repair: copy the right-hand coordinate matrix into the lower-right block
instead of overwriting it with ones.

## Why no further source edit is justified

FVK-F1 identifies the bug and traces it to PO-3. FVK-F2 confirms that V1 now
implements PO-3. FVK-F3 records the proof boundary: unrelated operators and
private direct helper call shapes are outside the public issue's required fix.

The candidate source does not change public signatures, dispatch tables, return
types, or test files, satisfying PO-6.

## Future checks

When execution is available, run:

```sh
kompile fvk/mini-python-separability.k --backend haskell
kast --backend haskell fvk/separability-spec.k
kprove fvk/separability-spec.k
```

Then run the project's relevant separability tests and add a regression test for
the nested right-hand compound case if test edits are permitted in a future task.

Do not remove existing tests based on this constructed proof alone.
