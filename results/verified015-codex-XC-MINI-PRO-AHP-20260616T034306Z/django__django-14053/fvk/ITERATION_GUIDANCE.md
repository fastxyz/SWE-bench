# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep V1 unchanged.

Reason: Findings F-001 through F-004 confirm that V1 satisfies the public
duplicate-yield intent and preserves the relevant error and compatibility
behavior. F-005 records the formalization boundary but does not identify a code
defect.

## Suggested Future Tests

Do not edit tests in this benchmark task. In a normal Django development pass,
the following tests would cover the public behavior:

1. An adjustable file whose hash changes across repeat passes is yielded once
   with the final hash.
2. An adjustable file whose hash is stable across repeat passes is yielded once.
3. A non-adjustable file is yielded once from the initial pass.
4. A URL conversion exception is yielded with the original failing path and
   collectstatic raises it.
5. A max-pass failure yields the existing `All` `RuntimeError` and does not
   report buffered adjustable successes as successful post-processed files.
6. `collectstatic`'s `post_processed` count uses unique successful original
   paths after `ManifestStaticFilesStorage.post_process()`.

## Machine-Check Follow-Up

When an execution environment is available, run:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/hashedfiles-post-process-spec.k
kprove fvk/hashedfiles-post-process-spec.k
```

The expected result is `#Top` for all abstract claims.

## No Further Source Changes Recommended

Avoid broadening the change into `_post_process()`, hash generation, manifest
format, or collectstatic. The issue is the public emission policy of
`post_process()`, and V1 fixes that without changing lower-level processing.
