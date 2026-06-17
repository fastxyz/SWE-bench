# Iteration Guidance

Status: constructed, not machine-checked.

## Verdict

V1 stands. The FVK audit did not surface a public-intent or proof-obligation failure requiring another source edit.

## Why no V2 code edit is justified

- F-001 and PO-001 show V1 addresses the reported crash by avoiding indexed reads when `sourcesContent` is absent.
- F-002 and PO-002 show V1 preserves the existing present-content copy behavior.
- F-003 and PO-004 show V1 correctly avoids inventing fallback content for original sources.
- PO-003 and PO-005 show the fix is locally framed and public-compatible.
- F-004 is a malformed-input hardening opportunity, not a public-intent blocker.

## Recommended future tests

Do not modify tests in this task. For a normal development pass, add or keep tests for:

1. `inputSourceMap` with `sources` and `mappings` but no `sourcesContent`.
2. `inputSourceMap` with `sourcesContent` present to confirm copied contents remain in the output map.
3. No-input-map `code` string behavior.
4. Object `code` behavior for multiple source filenames.

## Machine-check next step

In an environment with K installed, run:

```sh
kompile fvk/mini-ts-sourcemap.k --backend haskell
kast --backend haskell fvk/source-map-spec.k
kprove fvk/source-map-spec.k
```

Keep all tests until `kprove` returns `#Top`.
