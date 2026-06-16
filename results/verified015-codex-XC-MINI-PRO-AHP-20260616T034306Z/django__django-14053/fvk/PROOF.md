# Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/hashedfiles-post-process-spec.k
kprove fvk/hashedfiles-post-process-spec.k
```

Expected result after machine checking: `#Top` for the stated abstract claims.

## What Is Proved

For the yield-stream abstraction in `fvk/mini-python.k` and
`fvk/hashedfiles-post-process-spec.k`, the V1 emission policy satisfies:

1. Successful adjustable originals are not yielded during initial or repeat
   internal passes.
2. The latest adjustable result for each original path is retained by key.
3. After stabilization, each retained adjustable result is yielded once.
4. Non-adjustable initial-pass successful results are yielded once.
5. Exceptions are yielded immediately and stop processing.
6. Max-pass failure yields the existing `All` error and stops before flushing
   adjustable successes.

## Proof Sketch

### Initial-Pass Loop

Use induction over the initial pass event list.

Base case: with an empty initial list, the public output contains no new
successes and the deferred map contains no adjustable events from the initial
pass.

Step, non-adjustable success: the code takes the `else` branch at
`repo/django/contrib/staticfiles/storage.py:238-239` and appends exactly one
public tuple. The deferred map is unchanged.

Step, adjustable success: the code takes the branch at
`repo/django/contrib/staticfiles/storage.py:236-237` and updates
`processed_adjustable_paths[name]`. The public output is unchanged, so no
adjustable intermediate result is exposed.

Step, exception: the code yields `(name, hashed_name, processed)` and returns at
`repo/django/contrib/staticfiles/storage.py:233-235`, satisfying PO-006 and
ending the path.

This establishes PO-002.

### Repeat-Pass Loop

Use nested induction: outer induction over repeat passes, inner induction over
events in a pass.

Base case for a pass: no repeat event has been scanned, so the deferred map is
the latest map from prior passes and `substitutions` is false.

Step, adjustable success: the code updates
`processed_adjustable_paths[name]` at
`repo/django/contrib/staticfiles/storage.py:250`. Dictionary update semantics
replace the prior value for the same key, preserving one stored result per
original name. The public output is unchanged.

Step, substitutions flag: `substitutions = substitutions or subst` at
`repo/django/contrib/staticfiles/storage.py:251` computes the OR of all `subst`
values seen in the pass prefix.

Step, exception: the code yields the exception tuple and returns at
`repo/django/contrib/staticfiles/storage.py:247-249`.

This establishes PO-003.

### Stabilization

If a repeat pass finishes with `substitutions` false, the loop breaks at
`repo/django/contrib/staticfiles/storage.py:253-254`. The code then bypasses the
max-pass error and executes `yield from processed_adjustable_paths.values()` at
`repo/django/contrib/staticfiles/storage.py:260`.

Because a dictionary has one value per key, and keys are original path names,
each adjustable original is emitted once with the latest stored tuple. This
establishes PO-004 and the main success property in F-001 and F-002.

### Max-Pass Failure

If all allowed repeat passes are consumed while `substitutions` remains true,
the code yields `('All', None, RuntimeError(...))` and returns at
`repo/django/contrib/staticfiles/storage.py:256-258`. The return prevents the
deferred adjustable map from being flushed. This establishes PO-005.

### Collectstatic Count

`collectstatic` appends one `original_path` to `post_processed_files` for each
yielded non-exception tuple whose `processed` value is truthy at
`repo/django/contrib/staticfiles/management/commands/collectstatic.py:135-138`.
From PO-004, successful adjustable originals are yielded once. From PO-002,
non-adjustable successes are yielded once. Therefore duplicate successful yields
cannot inflate the count for a single original path. This establishes PO-007.

## Adequacy and Compatibility

The English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent-only
requirements in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` marks every item pass.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public signature or tuple-shape
break.

## Residual Risk

This is a partial-correctness proof over an abstract event model. It assumes
finite `_post_process()` event sequences and does not prove termination of file
I/O, hash computation, or URL rewriting. The proof is constructed but not
machine-checked, and test removal is not recommended without running the emitted
K commands in an environment that supports them.

## Test Guidance

Do not remove tests based on this un-machine-checked proof. Useful tests to keep
or add later are listed in `fvk/ITERATION_GUIDANCE.md`.
