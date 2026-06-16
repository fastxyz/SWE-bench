# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

This FVK pass audits the V1 fix for `django__django-13516`: `OutputWrapper.flush()`
in `repo/django/core/management/base.py`.

The proof target is the observable management-command behavior named by the issue:
after a command writes a partial progress line and calls `self.stdout.flush()` or
`self.stderr.flush()`, the wrapped stream is flushed rather than waiting until later
output or process exit.

## Formal artifacts

* `fvk/mini-management-output.k`: a minimal abstract K semantics for a management
  output wrapper, stream buffer visibility, and flush delegation.
* `fvk/outputwrapper-spec.k`: K reachability claims for flush delegation,
  no-flush compatibility, and partial-write-then-flush visibility.
* `fvk/INTENT_SPEC.md`: intent-only English obligations.
* `fvk/PUBLIC_EVIDENCE_LEDGER.md`: public evidence and provenance.
* `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of the K claims.
* `fvk/SPEC_AUDIT.md`: adequacy gate comparing formal English to intent.
* `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: public API/callsite compatibility audit.

## Public Intent Ledger

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`flush()` on self.stdout/stderr management commands doesn't work." | Command output wrappers must make explicit stdout/stderr flush calls effective. | Encoded in `FLUSH-DELEGATES`. |
| E2 | prompt | Expected migrate output shows `Applying ...` before work and `OK` later. | A partial write followed by flush must be visible before later completion output. | Encoded in `PARTIAL-WRITE-THEN-FLUSH`. |
| E3 | code | `migrate.py` calls `self.stdout.flush()` after partial-line writes at lines 278-301. | The migrate path already calls flush at the correct semantic point. | Localizes the bug to the wrapper. |
| E4 | code | `BaseCommand` wraps stdout/stderr in `OutputWrapper` at lines 243-245 and 386-389. | A shared wrapper fix covers default and custom command streams. | Compatibility audit C-1. |
| E5 | code | `OutputWrapper.__getattr__()` delegates unknown attributes, while `TextIOBase` supplies `flush`. | Without an explicit override, flush is not delegated by `__getattr__`. | Finding F-1, resolved by V1. |
| E6 | public-test | Custom stdout/stderr tests use `StringIO` and assert write output. | Preserve write behavior and custom stream handling. | PO-4, compatibility audit C-3. |

## Contract

For a wrapped stream with a `flush` method, `OutputWrapper.flush()` must call the
wrapped stream's `flush()` and return its result. Any output buffered before that call
must become visible according to the wrapped stream's flush semantics. This covers
`migrate` progress messages written with `ending=""` before long-running work.

For a stream-like object without a `flush` method, `OutputWrapper.flush()` is outside
the issue's positive delegation obligation. The compatibility contract is that the
wrapper must not raise merely because such an object lacks `flush`.

The contract does not change `OutputWrapper.write()`, style handling, line-ending
handling, `BaseCommand` construction, or command output formatting.

## Preconditions and Side Conditions

The formal model counts buffered output, visible output, and flush calls with
nonnegative integers. This is a default measurement-domain assumption for output
counters. There are no user-data preconditions added to Django management commands.

## Adequacy Verdict

The adequacy gate passes. The K claims paraphrase the prompt-derived behavior and do
not preserve the pre-fix no-op flush behavior. The no-flush branch is compatibility
preservation for custom stream-like objects, not a weakening of the required delegation
for streams that support `flush`.
