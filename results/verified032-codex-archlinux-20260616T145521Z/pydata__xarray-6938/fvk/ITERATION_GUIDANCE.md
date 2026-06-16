# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit found that V1 discharges the required no-mutation frame condition for the reported aliasing path. No finding requires an additional source edit.

## Why no V2 source edit is required

- F-001 and F-002 identify the real bug: mutating the result of `to_index_variable()` is unsafe because `IndexVariable.to_index_variable()` returns `self`.
- PO-002 is discharged by V1's `copy(deep=False)` before `.dims` assignment.
- PO-003 confirms the returned promoted variable still receives the rewritten dimensions.
- PO-005 and PO-006 confirm that validation behavior, public API, and return shape are unchanged.
- F-003 notes a possible narrower micro-optimization, but it is not required by public intent and would not change the proof result.

## Recommended future work

- Add a public regression test for the issue shape when test edits are in scope.
- Machine-check the K artifacts in an environment where K tooling is available.
- Keep existing tests until the proof is actually machine-checked.

## Commands to machine-check later

```sh
kompile fvk/mini-python-swapdims.k --backend haskell
kast --backend haskell fvk/swap-dims-spec.k
kprove fvk/swap-dims-spec.k
```
