# Proof

Status: constructed, not machine-checked.

## What is proved

For the audited command-state fragment of `makemigrations`, if `--check` is
present then all migration-writing paths reached by the command observe
`dryRun = true`. Consequently, normal creation, update writes/deletes, empty
migration writes, and merge migration writes perform zero abstract migration
file writes and deletes. When detected model changes exist on the normal or
update path, check mode exits with status `1`.

## Proof sketch

1. Initialization step: the mini semantics rewrites
   `handle(CHECK, DRYOPT, ...)` to `afterInit(...)` and sets `dryRun` to
   `DRYOPT orBool CHECK`. With `CHECK = true`, boolean simplification gives
   `dryRun = true`. This discharges PO-1 and claim C0.

2. Normal changes path: with `EMPTY = false`, `MERGE = false`, `UPDATE = false`,
   and `CHANGES = true`, `afterInit` rewrites to
   `writeFiles(dryRun) ~> setExit(1)`. From step 1, `dryRun = true`, so
   `writeFiles(true)` rewrites to `.K` without changing `writes` or `deletes`.
   `setExit(1)` sets `exitCode` to `1`. This discharges PO-2 and C1.

3. Update changes path: with `UPDATE = true` and `CHANGES = true`, `afterInit`
   rewrites to `writeUpdate(dryRun) ~> setExit(1)`. With `dryRun = true`,
   `writeUpdate(true)` rewrites to `.K` without changing `writes` or `deletes`.
   `setExit(1)` sets `exitCode` to `1`. This discharges PO-3 and C2 for the
   update path once update-specific validation reaches the writer.

4. No changes path: with `CHANGES = false`, `afterInit` rewrites directly to
   `setExit(0)`. No writer command is evaluated, so `writes` and `deletes`
   remain zero. This discharges PO-5 and C3.

5. Empty and merge paths: both paths dispatch to their writer command after
   initialization. Since `CHECK = true` made `dryRun = true`, `writeFiles(true)`
   and `mergeWrite(true)` leave `writes` and `deletes` unchanged. This
   discharges PO-4 and claims C4-C5 for no-write behavior.

6. Frame condition: with `CHECK = false` and `DRYOPT = false`, initialization
   leaves `dryRun = false`. The normal changes path evaluates
   `writeFiles(false)`, which increments the abstract write counter, then exits
   successfully. This discharges PO-6 and C6.

There are no loops in the audited abstract transition system, so no circularity
claim is required. The proof is partial correctness over the modeled command
states; termination and exact output text are outside the stated claims.

## Adequacy gate

The English paraphrases in `FORMAL_SPEC_ENGLISH.md` match the intent-only
obligations in `INTENT_SPEC.md` for the no-write and exit-status behavior the
issue requires. `SPEC_AUDIT.md` marks exact statuses for `--empty` and merge
paths as implementation-derived and not part of the success argument. The public
compatibility audit found no unhandled API or dispatch compatibility issue.

## Findings summary

- F-1 is the resolved pre-V1 bug: check mode wrote migrations before exiting.
- F-2 is a non-blocking residual dry-run behavior: `run_formatters([])` may
  still be called with no written files.
- F-3 is a test gap: public tests assert exit status but not no-write behavior.
- F-4 records that the proof is constructed, not machine-checked.

## Test-redundancy recommendation

No test files were changed. If the K proof is later machine-checked and returns
`#Top`, the exit-status part of `test_makemigrations_check` is partly subsumed
for the modeled in-domain cases. The test should still be kept unless the
project also has integration coverage for real Django autodetection, filesystem
isolation, and command wiring, because this FVK model abstracts those pieces.

A new regression test for no-write behavior would be valuable, but this task
forbids modifying tests.

## Commands to machine-check later

These commands were not executed in this environment.

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/makemigrations-check-spec.k
kprove fvk/makemigrations-check-spec.k
```

Expected result in a compatible K installation: `kprove` returns `#Top` for
all claims.
