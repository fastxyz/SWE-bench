# FVK Spec

Status: constructed, not machine-checked.

## Target

Target function:

`repo/django/contrib/staticfiles/storage.py:203`
`HashedFilesMixin.post_process(self, paths, dry_run=False, **options)`

Observable under audit:

The sequence of `(original_path, processed_path, processed)` tuples yielded to
`collectstatic` and to storage subclasses that consume `post_process()` directly.

Out of formal scope:

The contents of hashes, the exact CSS replacement language, storage backend I/O,
and `_post_process()` internals. They are modeled as an event source because the
public issue is about duplicate public yields across internal passes, not about
hash correctness.

## Domain

The formalized successful domain consists of finite `paths` mappings with unique
original path keys, a deterministic `matches_patterns()` partition into
adjustable and non-adjustable paths, and finite `_post_process()` pass events.
For successful calls, no `_post_process()` event has an exception and the
adjustable repeat loop stabilizes before `max_post_process_passes` is exhausted.

Exception and max-pass failure paths are specified separately.

## Public Intent Ledger

The ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

1. Multi-pass processing is necessary and must remain internal.
2. A successful original filename must be yielded at most once.
3. Adjustable files must be yielded with the final stable hashed name, not an
   intermediate hash.
4. Non-adjustable files preserve their single initial-pass yielded result.
5. Exception tuples remain immediate failure signals.
6. Max-pass failure yields the existing `All` `RuntimeError` and stops.
7. The public tuple shape and method signature remain unchanged.

## Abstract Model

`_post_process()` is abstracted into events:

`ev(name, adjustable, hashed_name, processed, substitutions)`

`ex(name)`

`ev` represents a successful result from one internal pass. `ex` represents the
exception tuple shape produced by `_post_process()` when URL conversion fails.

The V1 `post_process()` policy is modeled as:

1. Scan the initial pass over all paths.
2. Yield non-adjustable successful events immediately.
3. Store adjustable successful events in a map keyed by `name`.
4. For each repeat pass over adjustable paths, update that map keyed by `name`.
5. If any event is an exception, yield that exception and stop.
6. If max passes are exhausted while substitutions are still true, yield the
   existing `All` error and stop.
7. On success, yield the map values once, exposing each adjustable original once
   with its final stored result.

This abstraction is property-complete for the reported defect because it
preserves the axis under test: yielded stream cardinality by original path and
whether intermediate adjustable results are exposed.

## Formal Claims

The K artifacts are:

- `fvk/mini-python.k`
- `fvk/hashedfiles-post-process-spec.k`

Claim names:

- `POST-PROCESS-SUCCESS`
- `POST-PROCESS-FIRST-PASS-ERROR`
- `POST-PROCESS-REPEAT-PASS-ERROR`
- `POST-PROCESS-MAX-ERROR`

The commands that would machine-check the constructed proof are:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/hashedfiles-post-process-spec.k
kprove fvk/hashedfiles-post-process-spec.k
```

These commands were not run, per the task constraints.

## Required Postconditions

On dry-run:

No public tuples are yielded and no hash manifest state is updated.

On successful non-dry-run:

1. Every yielded successful original path is unique.
2. Every non-adjustable successful initial-pass event is yielded once.
3. Every adjustable original path is yielded once.
4. Each adjustable yield equals the last successful result recorded for that
   path by the stabilizing repeat pass, or by the initial pass if no repeat pass
   is modeled.
5. No intermediate adjustable result is yielded.
6. The yielded tuple shape remains `(name, hashed_name, processed)`.
7. After the generator is fully consumed, `self.hashed_files` is updated with the
   same final `hashed_files` map produced by internal processing.

On `_post_process()` exception:

The exception tuple is yielded immediately and processing stops. Buffered
adjustable successes are not flushed after the exception.

On max-pass failure:

The existing `('All', None, RuntimeError('Max post-process passes exceeded.'))`
tuple is yielded and processing stops. Buffered adjustable successes are not
flushed after this failure.

## Frame Conditions

The change does not alter:

- `post_process()` method signature.
- `_post_process()` signature or file-saving behavior.
- `hashed_name()`, URL conversion, storage backend calls, or manifest format.
- `collectstatic` tuple consumer shape.

## Adequacy Notes

The formal model deliberately abstracts away hash bytes and file contents, but it
does not abstract away successful-yield cardinality, original-path identity,
exception immediacy, or max-pass failure shape. Those are the properties named
by the public issue.
