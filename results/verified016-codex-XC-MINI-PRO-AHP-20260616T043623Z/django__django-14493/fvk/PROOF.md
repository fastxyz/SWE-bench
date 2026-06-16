# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## What Is Proved

For the audited tail of `HashedFilesMixin.post_process()`, assuming a non-negative `max_post_process_passes` and finite `_post_process()` pass outcomes:

- `max_post_process_passes == 0` reaches the final `if substitutions:` with `substitutions == False`.
- The zero-pass path does not raise `UnboundLocalError` and does not yield the synthetic max-exceeded `RuntimeError`.
- For positive pass counts, V1 preserves the previous loop behavior because the loop still resets `substitutions = False` at the start of each iteration before OR-ing per-file `subst` values.

The proof is partial correctness. It does not prove `_post_process()` termination, filesystem correctness, hash correctness, URL rewrite correctness, or manifest correctness.

## Adversarial Reproduction Of The Pre-V1 Bug

Use the reduced model `legacyPostProcessTail(P, B)` for the code before the V1 initializer.

For `P = 0`, Python's `range(0)` produces zero iterations. In the legacy model no assignment to `substitutions` occurs before the final branch. The claim `LEGACY_ZERO_PASS_REPRODUCES_BUG` rewrites:

```k
<k> legacyPostProcessTail(0, BS) => unboundLocal ... </k>
```

This matches the public traceback and localizes the cause: the final branch reads a local that was only assigned inside a skipped loop.

## V1 Zero-Pass Proof

In V1, symbolic execution starts after the initial post-processing pass and path filtering. The source executes:

```python
substitutions = False
for i in range(self.max_post_process_passes):
    ...
if substitutions:
    ...
```

For `P = 0`, the assignment step binds `substitutions` to `False`. The loop body has zero iterations. The final branch reads the bound value `False`, so the max-exceeded yield is skipped.

The K claim `V1_ZERO_PASS` captures the same transition:

```k
<k> postProcessTail(0, BS) => ok(false) ... </k>
```

This discharges PO1 and PO2.

## Positive-Pass Preservation Proof

For `P > 0`, the first loop iteration executes. The first statement inside the loop remains:

```python
substitutions = False
```

Therefore the V1 pre-loop value is overwritten before any `_post_process()` result contributes to the loop result. The inner loop and break condition are unchanged:

```python
substitutions = substitutions or subst
if not substitutions:
    break
```

The abstract final value is:

- `False` if a repeated pass reports no substitutions and breaks the loop.
- `True` if all `P` allowed repeated passes report substitutions and the loop is exhausted.

The claims `V1_POSITIVE_PASS` and `LEGACY_POSITIVE_PASS` rewrite positive-pass inputs to the same `resultForFinal(finalSubstitutions(P, BS))`, discharging PO3. The claim `V1_MAX_EXCEEDED` discharges PO4 for the `True` final value.

## Frame And Compatibility Proof

The source diff adds only one local assignment immediately before the repeated-pass loop. It does not alter:

- the method signature,
- `dry_run` handling,
- construction of `hashed_files`,
- construction of `adjustable_paths`,
- the initial `_post_process()` pass,
- the dictionary of processed adjustable paths,
- the `hashed_files` update,
- the final yield of processed adjustable paths,
- `ManifestFilesMixin.post_process()`,
- `collectstatic`'s consumption of result triples.

This discharges PO5 and PO6 by source inspection.

## Machine-Check Commands

These commands are the commands to run later in an environment with K installed. They were intentionally not executed in this benchmark session.

```sh
kompile fvk/mini-staticfiles.k --backend haskell
kast --backend haskell fvk/staticfiles-spec.k
kprove fvk/staticfiles-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for the stated claims.

## Test Guidance

No tests were read, run, modified, or removed.

Recommended test to keep or add in the fixed test suite: a regression case using a `ManifestStaticFilesStorage` subclass with `max_post_process_passes = 0` and at least one adjustable static file path, asserting `collectstatic`/`post_process()` does not raise `UnboundLocalError`.

No test-removal recommendation is made. The proof is constructed, not machine-checked, and the benchmark forbids editing tests.

## Residual Risk

The proof depends on the adequacy of the reduced K model for the audited property. It intentionally abstracts `_post_process()` to per-pass substitution booleans, so it cannot establish unrelated file hashing or URL rewriting behavior.

The source-level conclusion is still strong for the reported bug because the failing path is a pure control-flow definedness issue: a local variable is read after a loop that may execute zero times. V1 creates a binding before that loop.
