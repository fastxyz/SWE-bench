# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Adjustable Partition

`adjustable_paths` is the set of original path keys matching `self._patterns`.
This partition remains fixed for the whole `post_process()` call.

Evidence: `repo/django/contrib/staticfiles/storage.py:224-228`.

Needed for: distinguishing one-pass non-adjustable outputs from buffered
adjustable outputs.

## PO-002: Initial-Pass Loop Invariant

After scanning any prefix of the initial `_post_process()` output:

1. The public output contains exactly the successful non-adjustable events from
   that prefix, in their scan order.
2. The deferred map contains the latest successful adjustable event from that
   prefix for each adjustable original name.
3. No successful adjustable event has been yielded publicly.
4. If an exception event is encountered, it is yielded and the function returns.

Evidence: `repo/django/contrib/staticfiles/storage.py:232-239`.

Needed for: hiding first-pass intermediate adjustable hashes while keeping
non-adjustable one-pass behavior.

## PO-003: Repeat-Pass Loop Invariant

After scanning any prefix of any repeat pass:

1. The public output for successful events is unchanged.
2. The deferred map contains the latest successful adjustable event seen so far
   for each adjustable original name.
3. The pass-local `substitutions` flag is the boolean OR of `subst` values seen
   in the current pass.
4. If an exception event is encountered, it is yielded and the function returns.

Evidence: `repo/django/contrib/staticfiles/storage.py:244-251`.

Needed for: proving repeated passes update final results without creating
duplicate public yields.

## PO-004: Stabilization Flush

If a repeat pass completes with `substitutions` false, the loop breaks and the
function yields the deferred map values once.

Evidence: `repo/django/contrib/staticfiles/storage.py:253-260`.

Needed for: proving each adjustable original appears exactly once with the final
stable result.

## PO-005: Max-Pass Failure

If the repeated processing loop exits after exhausting the maximum pass count
with `substitutions` still true, the function yields the existing `All`
`RuntimeError` tuple and returns before flushing deferred adjustable successes.

Evidence: `repo/django/contrib/staticfiles/storage.py:256-258`.

Needed for: preserving public failure behavior without exposing buffered
intermediate adjustable successes.

## PO-006: Exception Immediacy

Any exception value in the `processed` position is yielded immediately and the
function returns.

Evidence: `repo/django/contrib/staticfiles/storage.py:233-235` and
`repo/django/contrib/staticfiles/storage.py:247-249`.

Needed for: preserving collectstatic's exception handling contract.

## PO-007: Collectstatic Count Correctness

Because `collectstatic` appends one `original_path` for each yielded tuple whose
`processed` value is truthy and not an exception, uniqueness of successful
yielded original paths prevents duplicate successful entries from inflating the
post-processed count.

Evidence: `repo/django/contrib/staticfiles/management/commands/collectstatic.py:128-138`.

Needed for: satisfying the primary issue symptom.

## PO-008: Compatibility Frame

The method signature, yielded tuple shape, `_post_process()` API, and manifest
format remain unchanged.

Evidence: V1 diff only changes buffering/yield timing inside
`HashedFilesMixin.post_process()`.

Needed for: confirming the repair does not break the public call protocol.
