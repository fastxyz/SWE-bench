# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Verdict

V1 stands unchanged.

The FVK audit found one production-code bug required by public intent: the pre-V1 zero-pass path read `substitutions` without a binding. V1 fixes that by assigning `substitutions = False` before the repeated-pass loop.

## Code Changes Recommended Now

No additional source changes are recommended.

Rationale:

- F1 is resolved by PO1 and PO2.
- F2 rejects the broader "skip all processing when pass count is zero" alternative because it conflicts with PO5.
- F3 confirms positive-pass behavior preservation through PO3 and PO4.
- F4 confirms public compatibility through PO6.

## Code Changes Rejected

Skipping the initial `_post_process()` pass when `max_post_process_passes == 0` is rejected. The public issue identifies the `UnboundLocalError`, while the source comments and docstring show that an initial pass is part of normal post-processing independent of the repeated-pass limit.

Replacing the final `if substitutions:` condition with a loop-count conditional is rejected. The required property is a bound branch value on the zero-iteration path; initializing the local directly is the smaller and better-targeted fix.

Adding a guard that rejects `max_post_process_passes = 0` is rejected. The public reproduction treats zero as an intended configuration.

## Verification Follow-Up

When an execution environment with K is available, run:

```sh
kompile fvk/mini-staticfiles.k --backend haskell
kast --backend haskell fvk/staticfiles-spec.k
kprove fvk/staticfiles-spec.k
```

If the local K version requires syntax adjustments, keep the same claims and provenance while repairing only the artifact syntax.

## Test Follow-Up

Do not remove tests based on this proof unless the K claims are machine-checked.

Add or keep a regression test for a `ManifestStaticFilesStorage` subclass with `max_post_process_passes = 0`, exercising `post_process()` through the same generator path used by `collectstatic`.

Keep integration tests around `collectstatic`, hashing, manifest saving, and URL rewriting because the reduced proof does not cover those behaviors.

## Residual Questions

No user clarification is needed for the V1 decision. The only alternative interpretation, "zero means skip all processing," is contradicted by the source-level initial-pass structure and the public workaround note that points to `patterns = ()` when callers want to disable adjustment patterns.
