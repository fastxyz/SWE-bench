# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep V1 unchanged.

Justification:

- FVK-001 identifies the only issue-backed code bug: `replace` failed to transfer `userData`.
- PO-3 is discharged by the V1 assignment `userData = other.userData`.
- PO-5 confirms the V1 edit does not disturb write-once metadata frame conditions.
- FVK-002 rejects a defensive-copy refactor as broader than the public issue and unnecessary under
  local source conventions.
- PO-6 confirms no public compatibility work is needed.

## Recommended Next Checks

If an execution environment is available later, run the recorded K commands:

```sh
kompile fvk/mini-java-segmentinfos.k --backend haskell
kast --backend haskell fvk/segmentinfos-replace-spec.k
kprove fvk/segmentinfos-replace-spec.k
```

If project tests can be added in a normal development setting, add a source-level regression test
for the explicit-commit initialization path:

```text
commit A with userData A
commit B with userData B
initialize/open using commit A while latest is B
assert live/commit data after replace is A, not B
```

Do not remove any tests based on this FVK pass. The proof is constructed, not machine-checked, and
the benchmark's fixed test suite is hidden.

## Open Questions

None that block the source fix. Null handling for `replace(null)` remains outside the specified
domain because the issue, method visibility, and callers all assume a non-null `SegmentInfos`.
