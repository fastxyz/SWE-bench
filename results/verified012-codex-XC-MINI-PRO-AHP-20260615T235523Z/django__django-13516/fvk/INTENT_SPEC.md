# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Scope

This FVK pass audits the V1 change for `django.core.management.base.OutputWrapper`,
focused on management-command stdout/stderr flushing and the `migrate` progress path
described in `benchmark/PROBLEM.md`.

## Intent-only obligations

INT-1. `self.stdout.flush()` and `self.stderr.flush()` on Django management commands
must behave like flushing the wrapped output stream when that stream supports `flush`.

Evidence: `benchmark/PROBLEM.md` says "flush() on self.stdout/stderr management
commands doesn't work."

INT-2. A partial progress line written by `migrate` before long-running migration work
must become visible after the explicit flush, before the later success suffix is written.

Evidence: `benchmark/PROBLEM.md` expected output shows
`Applying myapp.0002_auto_20200817_1030...` before "then work" and `OK` after it.

INT-3. The fix must apply to both default command streams and custom streams passed
through `BaseCommand(stdout=...)`, `BaseCommand(stderr=...)`, or `call_command(...,
stdout=..., stderr=...)`.

Evidence: `OutputWrapper` is the shared wrapper around stdout/stderr, and public tests
exercise custom stdout/stderr wrapping through `StringIO`.

INT-4. Existing management-command writing behavior must be preserved: styling, line
ending handling, custom stdout/stderr replacement, and command output formatting are
not part of the reported defect.

Evidence: the issue specifically concerns explicit `flush()` calls, while public tests
cover stdout/stderr write behavior.

INT-5. A stream-like object without a `flush` attribute is outside the positive
delegation obligation. It should not fail merely because `OutputWrapper` exposes
`flush()`.

Evidence: Django management commands accept custom stream-like objects; no public
requirement says such objects must implement `flush`.
