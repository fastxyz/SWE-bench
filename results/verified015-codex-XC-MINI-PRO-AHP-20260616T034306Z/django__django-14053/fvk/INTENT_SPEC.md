# Intent Spec

Status: constructed from public evidence, not machine-checked.

## Scope

This FVK pass audits the V1 change to
`django.contrib.staticfiles.storage.HashedFilesMixin.post_process()` and its
observable generator stream as consumed by `collectstatic`. It does not attempt
to prove the cryptographic hash function, file I/O, pattern matching, or CSS
URL rewriting. Those are modeled as the lower-level `_post_process()` event
source because the reported issue concerns which events are yielded to public
callers.

## Required Behaviors

I1. Multi-pass processing is required and must remain internal.

Evidence: `benchmark/PROBLEM.md:6-7` says several passes are necessary and not a
problem in themselves.

Obligation: The implementation may keep running repeated internal passes for
adjustable files until substitutions stabilize or the maximum pass limit is hit.

I2. Successful `post_process()` output must not include duplicate successful
results for the same original filename.

Evidence: `benchmark/PROBLEM.md:7`, `benchmark/PROBLEM.md:14-19`, and
`benchmark/PROBLEM.md:24-28`.

Obligation: On a successful non-dry-run call, each original path appears in the
successful yielded stream at most once. `collectstatic` may count yielded
successful entries as post-processed files without inflating the count.

I3. Adjustable files must be reported with the final stable hashed name, not an
intermediate hashed name.

Evidence: `benchmark/PROBLEM.md:11-17` shows an intermediate hash followed by the
expected final hash, and `benchmark/PROBLEM.md:21-23` says intermediate files are
a lower-level implementation detail that should not be passed to collectstatic
or subclasses.

Obligation: For an adjustable original file, the yielded successful tuple is the
last successful tuple produced by the stabilizing internal pass for that
original name.

I4. Non-adjustable files keep the existing single-pass reporting behavior.

Evidence: `repo/django/contrib/staticfiles/storage.py:207-215` says either
renaming/copying or reference adjustment counts as post-processing; the issue's
complaint is specifically repeated yields created by repeated adjustable passes.

Obligation: A successful non-adjustable tuple from the initial pass may be
yielded immediately and appears once.

I5. Exception tuples remain immediate failure signals.

Evidence: `repo/django/contrib/staticfiles/management/commands/collectstatic.py:128-134`
raises as soon as a yielded `processed` value is an exception.

Obligation: If `_post_process()` yields an exception tuple, `post_process()`
yields that tuple and stops rather than buffering it behind later successes.

I6. If the maximum pass limit is exceeded, the public failure remains the
existing `All` `RuntimeError`.

Evidence: `benchmark/PROBLEM.md:35` mentions the maximum pass failure, and V1
preserves the existing `RuntimeError('Max post-process passes exceeded.')`
surface.

Obligation: On max-pass failure, `post_process()` yields the existing `All`
exception tuple and does not flush buffered adjustable successes.

I7. Public API compatibility is preserved.

Evidence: `collectstatic` consumes `(original_path, processed_path, processed)`
tuples at `repo/django/contrib/staticfiles/management/commands/collectstatic.py:128`.

Obligation: The method signature and yielded tuple shape must not change.
