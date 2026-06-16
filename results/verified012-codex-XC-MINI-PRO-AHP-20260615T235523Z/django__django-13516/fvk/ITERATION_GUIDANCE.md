# Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

V1 stands unchanged.

Reasoning:

* Finding F-1 identifies the original defect and is resolved by PO-1 and PO-3.
* Finding F-2 confirms the `hasattr()` guard is a compatibility-preserving choice,
  supported by PO-2 and PO-4.
* Finding F-3 is a proof-process limitation, not a source-code defect.
* The adequacy gate PO-5 passes; the proof does not certify the reported legacy
  no-op behavior.
* The compatibility audit found no API, signature, virtual-dispatch, or callsite issue.

## Recommended Future Test Additions

Do not modify tests in this task. Future public tests could cover:

* `OutputWrapper.flush()` delegates to a custom stream's `flush()` and returns that
  method's result.
* `OutputWrapper.flush()` on a stream-like object without `flush` returns `None`
  without raising.
* `migrate.Command.migration_progress_callback("apply_start", ...)` flushes after
  writing the partial `Applying ...` message.

## No Recommended Test Removals

No existing public tests should be removed. The proof is constructed but not
machine-checked, and the audited public tests are compatibility coverage rather than
redundant point checks of the new formal contract.

## If A Future Machine Check Fails

First inspect K syntax/module-path issues in the abstract artifacts, because no K tooling
was available here. If the semantic obligation itself fails, revisit PO-1 and PO-3 before
changing code: the public intent requires delegation and partial-write visibility.
