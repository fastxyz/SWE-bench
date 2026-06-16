# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No additional production-code edit is justified by this FVK audit. The V1 change, `newline=""` on the fd-capture `EncodedFile`, directly discharges the carriage-return preservation obligations for stdout and stderr while preserving binary capture and public APIs.

## Why V1 Stands

F-001 identifies the original bug and marks it resolved by PO-001 through PO-004.

F-002 checks the shared binary path and is discharged by PO-005.

F-003 checks public compatibility and is discharged by PO-006.

No finding reports an unresolved source-code mismatch against the public intent.

## Future Code Changes

None recommended for this issue.

The alternative of decoding bytes manually inside `FDCapture.snap()` remains rejected: it would duplicate `EncodedFile` decoding behavior and leave the text wrapper itself in the legacy translation mode, while PO-001 and PO-002 show that configuring the wrapper is the direct fix.

The alternative of changing `EncodedFile` globally remains unnecessary: PO-001 only requires the fd-capture construction site, and PO-006 favors the narrower public-compatibility-preserving edit.

## Future Tests

F-005 recommends adding a regression test for `capfd` preserving `"\r"`. This task forbids modifying tests, so no test files were edited.

## Machine Verification Follow-up

A future environment with K installed should run:

```sh
kompile fvk/mini-capture.k --backend haskell
kast --backend haskell fvk/capture-spec.k
kprove fvk/capture-spec.k
```

Until `kprove` returns `#Top`, the proof remains constructed, not machine-checked.
