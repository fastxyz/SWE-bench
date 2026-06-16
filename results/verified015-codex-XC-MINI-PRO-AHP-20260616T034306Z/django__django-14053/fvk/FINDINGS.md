# Findings

Status: constructed, not machine-checked. No tests or code were run.

## F-001: V1 Discharges the Duplicate-Yield Intent

Classification: confirmed behavior by inspection and constructed proof.

Input shape: a successful non-dry-run `post_process()` call where an adjustable
path, for example `admin/css/base.css`, appears in the initial pass and in one or
more repeat passes.

Pre-fix observed behavior from public issue:

`admin/css/base.css` was yielded multiple times, including intermediate and
repeated final hashes.

Expected behavior from public issue:

`admin/css/base.css` is yielded once as the final stable hashed name.

V1 mechanism:

`repo/django/contrib/staticfiles/storage.py:236-237` stores first-pass adjustable
results instead of yielding them. `repo/django/contrib/staticfiles/storage.py:250`
overwrites that stored result during repeat passes. `repo/django/contrib/staticfiles/storage.py:260`
flushes the deferred map once after stabilization.

Related proof obligations: PO-002, PO-003, PO-004, PO-007.

Decision: no additional source edit is required for this finding.

## F-002: Stable Adjustable Files Are Also Deduplicated

Classification: confirmed behavior by inspection and constructed proof.

Input shape: an adjustable path whose repeated passes produce the same final
hash, for example the `admin/css/dashboard.css` pattern in the public issue.

Pre-fix observed behavior from public issue:

The same original path and same final hash were yielded repeatedly.

Expected behavior:

The original path is yielded once.

V1 mechanism:

Repeated assignments to `processed_adjustable_paths[name]` replace the prior
entry for the same original name. The final `yield from
processed_adjustable_paths.values()` emits one value per dictionary key.

Related proof obligations: PO-003, PO-004, PO-007.

Decision: no additional source edit is required for this finding.

## F-003: Exception Behavior Remains Immediate

Classification: compatibility confirmation.

Input shape: `_post_process()` yields `(name, None, exc, False)` because URL
conversion failed.

Expected behavior:

`post_process()` yields `(name, None, exc)` immediately so `collectstatic` can
raise the same error with the same original path.

V1 mechanism:

Both the first-pass and repeat-pass loops check `isinstance(processed,
Exception)`, yield the exception tuple, and return.

Related proof obligations: PO-006, PO-008.

Decision: no additional source edit is required for this finding.

## F-004: Max-Pass Failure Does Not Flush Deferred Adjustable Successes

Classification: compatibility confirmation.

Input shape: repeated adjustable processing still has substitutions after
`max_post_process_passes`.

Expected behavior:

The existing `All` `RuntimeError` is yielded as the public failure. Intermediate
adjustable successes are not reported as successful post-processed files.

V1 mechanism:

`repo/django/contrib/staticfiles/storage.py:256-258` yields the `All` error and
returns before the deferred adjustable map is flushed.

Related proof obligations: PO-005, PO-006.

Decision: no additional source edit is required for this finding.

## F-005: Formalization Boundary Is Intentional, Not a Code Defect

Classification: proof capability boundary.

The K model abstracts `_post_process()` into pass events and does not prove hash
content, storage I/O, or CSS URL rewriting. This is sufficient for the reported
defect because the public issue concerns duplicate public generator yields by
original filename. It would not be sufficient for a separate issue about hash
correctness or URL rewriting correctness.

Related proof obligations: PO-001 through PO-008.

Decision: keep V1 unchanged; add no broader source refactor.
