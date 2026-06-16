# FVK Findings

Status: constructed, not machine-checked. Findings do not rely on hidden tests,
internet access, or evaluator results.

## F-1: Pre-V1 wrapper flush did not delegate

Input:

* A management command has `self.stdout = OutputWrapper(out)`.
* `out` supports `flush()`.
* The command writes a partial progress line and calls `self.stdout.flush()`.

Observed before V1:

* `OutputWrapper` inherited `TextIOBase.flush()`.
* Because `flush` already existed on the superclass, `OutputWrapper.__getattr__()` did
  not delegate the lookup to `out.flush`.
* The partial progress line could remain buffered until later output or process exit.

Expected:

* `self.stdout.flush()` and `self.stderr.flush()` delegate to the wrapped stream's
  `flush()` when present.
* In `migrate`, `Applying ...` is visible before the migration work, and `OK` is
  appended later.

Status:

* Resolved by V1. `OutputWrapper.flush()` now explicitly returns `_out.flush()` when
  the wrapped stream has `flush`.
* Traced to PO-1 and PO-3.

## F-2: Compatibility for stream-like objects without flush

Input:

* A custom command stream object supports `write()` but has no `flush` attribute.
* User code or command code calls `self.stdout.flush()`.

Observed in V1:

* `OutputWrapper.flush()` checks `hasattr(self._out, 'flush')` and otherwise returns
  `None`.

Expected:

* The issue's positive obligation only requires delegation for streams with `flush`.
* A stream-like object without `flush` should not fail merely because the wrapper now
  exposes a `flush()` method.

Status:

* Confirmed compatible. No additional source change is justified.
* Traced to PO-2 and PO-4.

## F-3: Formal proof is constructed, not machine-checked

Input:

* The FVK artifacts include `mini-management-output.k` and `outputwrapper-spec.k`.

Observed:

* The task forbids running K tooling, Python, or tests.

Expected:

* Artifacts include exact commands and expected outcome, but no claim of machine-checked
  proof or test-removal authority.

Status:

* Residual proof-process limitation, not a code bug.
* Traced to PO-5 and PO-6.

## Proof-derived findings from `/verify`

No new code bug was found. The proof obligations close on the constructed semantics by
direct symbolic execution: the only precondition needed is that output counters are
nonnegative in the abstract model. That side condition is a measurement-domain
assumption, not a Django API restriction.

No tests should be removed. The proof is not machine-checked, and the existing public
tests identified during the audit are compatibility tests for command output wiring
rather than redundant direct assertions of the new `flush()` contract.
