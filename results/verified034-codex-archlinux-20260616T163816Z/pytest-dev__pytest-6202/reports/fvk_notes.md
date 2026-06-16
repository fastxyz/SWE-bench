# FVK Notes

## Decision: keep V1 unchanged

FVK Finding F-01 identifies the real bug as the legacy global `s.replace(".[", "[")` rewrite corrupting literal parametrized ids. Proof obligations O-01 and O-05 require `getmodpath()` to return the dotted join of projected node-name parts without post-join content normalization. V1 already implements that by returning `s`, so no further source edit is justified.

## Decision: do not add a narrower `".["` special case

Finding F-02 and obligation O-04 trace the old rewrite to generated-yield-test formatting. The public hint and current source both show that yield tests are removed/ignored in this checkout, so a special case for old `[0]` children would preserve obsolete behavior and reintroduce string-level interpretation of node-name contents. I rejected that alternative.

## Decision: do not edit report propagation code

Finding F-03 and obligation O-03 show that `reportinfo()`, `Node.location`, `TestReport.head_line`, and the terminal reporter propagate the modpath string. Once `getmodpath()` returns `test_boo[..[]`, those layers do not rewrite it. Editing `reports.py`, `nodes.py`, or `terminal.py` would be broader than the proof obligations require.

## Decision: do not modify tests

Finding F-05 recommends future coverage for parametrized ids containing `".["`, but the task forbids modifying tests. Finding F-04 also records that the FVK proof is constructed, not machine-checked, so no test deletion would be justified even outside this task.

## Artifacts

The FVK audit artifacts are in `fvk/SPEC.md`, `fvk/FINDINGS.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.

I also added the constructed formal-core skeletons `fvk/mini-pytest-modpath.k` and `fvk/pytest-modpath-spec.k` so the commands recorded in O-06 point at concrete files. They are documentation artifacts in this no-execution session, not machine-checked proof results.
