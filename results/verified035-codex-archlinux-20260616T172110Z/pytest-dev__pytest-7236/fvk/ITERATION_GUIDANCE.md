# Iteration Guidance

Status: constructed, not machine-checked.

## Source Decision

Keep V1 unchanged. The audit found no source issue requiring a V2 edit:

- PO-1 closes F-001, the reported skipped-test regression.
- PO-2 confirms the delayed-teardown behavior remains intact for tests that
  reach unittest teardown under `--pdb`.
- PO-3 confirms the non-`--pdb` delayed-teardown path remains inactive.
- PO-4 finds no public compatibility break.
- PO-5 confirms the spec is intent-derived and discriminates the buggy
  predecessor from V1.

## Recommended Tests

Do not modify tests in this task.

For a future unrestricted development pass, add or keep a test with the issue's
shape: a `unittest.TestCase` method decorated with `@unittest.skip`, plus a
`tearDown` that would fail if called, run with `--pdb`, expecting only a skip and
no teardown error.

Keep integration tests for real pytest/PDB process behavior, because the FVK
mini semantics proves only the internal scheduling state.

## Machine-Check Follow-Up

In an environment with K installed, run:

```sh
kompile fvk/mini-pytest-unittest.k --backend haskell
kast --backend haskell fvk/pytest-unittest-teardown-spec.k
kprove fvk/pytest-unittest-teardown-spec.k
```

Expected outcome: `#Top` for all claims.

## Next Code Prompt If This Regresses

If a future change reintroduces the issue, require the implementation to record
the delayed `tearDown` only as a consequence of unittest calling the replacement
`tearDown`, not merely because `--pdb` is active before unittest runs the test
case.
