# Baseline Notes

## Root cause

`HashedFilesMixin.post_process()` checked `substitutions` after the loop that performs repeated post-processing passes over adjustable static files. The variable was initialized inside that loop, so a storage subclass with `max_post_process_passes = 0` skipped the loop entirely and then evaluated an unbound local variable.

## Changed files

`repo/django/contrib/staticfiles/storage.py`

Initialized `substitutions` to `False` before the repeated-pass loop. This makes the zero-pass case behave like a pass that made no further substitutions, avoiding the `UnboundLocalError` while preserving the existing behavior for positive pass counts and the existing "max passes exceeded" check.

## Assumptions

The intended meaning of `max_post_process_passes = 0` is to disable the additional stabilization passes after the initial post-processing pass, not to disable all hashed-file post-processing. This matches the existing structure of `post_process()`, which always performs one initial pass before consulting `max_post_process_passes`.

## Alternatives considered

Skipping the initial pass when `max_post_process_passes` is zero was rejected because it would change broader staticfiles behavior and bypass the existing copy/hash work done before the repeated-pass loop.

Replacing the final `if substitutions:` condition with a conditional tied to the loop count was rejected as less direct. The immediate bug is that `substitutions` lacks a safe default when the loop does not run.
