# FVK ITERATION GUIDANCE - sympy__sympy-11618

Status: V1 stands.

## Code Decision

No additional source edits are required after the V1 patch.

Reason:

- F-001 is resolved by PO-001 and PO-002.
- F-002 confirms same-dimensional compatibility through PO-003.
- F-003 does not create a code-change obligation because the allowed public
  evidence targets `.distance` and the Euclidean `sqrt(5)` result.
- F-004 requires honesty about machine checking, not a source change.

## Recommended Follow-Up Tests

Do not edit tests in this task. If tests are added later, useful public cases
would be:

```python
assert Point(2, 0).distance(Point(1, 0, 2)) == sqrt(5)
assert Point(1, 0, 2).distance(Point(2, 0)) == sqrt(5)
assert Point(2, 0).distance((1, 0, 2)) == sqrt(5)
assert Point(1, 1).distance(Point(4, 5)) == 5
```

The first three exercise the mixed-dimensional obligation. The last one
protects the same-dimensional frame condition.

## Machine-Check Guidance

The formal artifacts are constructed only. To upgrade them to machine-checked,
run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/point-distance-spec.k
kprove fvk/point-distance-spec.k
```

Expected result:

`#Top`.

## Next Iteration Risks

The only underspecified area found is adjacent mixed-dimensional behavior in
methods other than `.distance` (F-003). A future issue or maintainer decision
could choose to zero-fill those methods too, but this task's public intent does
not require it.
