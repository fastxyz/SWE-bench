# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Active clear preserves the current records reference

Precondition: during active phase `P`, handler records reference `R` is also
stored in `stash[P]`, and heap object `R` contains any list `L`.

Postcondition: after `caplog.clear()`, handler records reference is still `R`,
`stash[P]` is still `R`, heap object `R` contains `.List`, and stream content is
empty.

Discharged by: `CLEAR-CURRENT` claim and V1 `LogCaptureHandler.clear()` using
`self.records.clear()`.

## PO-2: Records emitted after clear append to the current phase list

Precondition: PO-1 precondition and a later emitted record `B`.

Postcondition: after `caplog.clear(); emit(B)`, handler records and `stash[P]`
still reference `R`, and heap object `R` contains exactly `[B]`.

Discharged by: `CLEAR-THEN-EMIT` claim and `emit()` appending to
`self.records`.

## PO-3: Phase reset preserves previous phase records

Precondition: setup has stash reference `RS` with contents `SETUP`; pytest
begins the call phase.

Postcondition: call phase receives a fresh records reference `RC`; setup stash
still references `RS`; heap object `RS` still contains `SETUP`.

Discharged by: `BEGIN-PHASE-PRESERVES-PREVIOUS` claim and V1 leaving
`LogCaptureHandler.reset()` as list replacement.

## PO-4: Text content is cleared

Precondition: stream content may contain previous formatted log text.

Postcondition: after `caplog.clear()`, `caplog.text` observes empty text until a
later emit.

Discharged by: V1 `LogCaptureHandler.clear()` assigning a fresh `StringIO`.
The public obligation is text content, not identity of the private stream
object.

## PO-5: Public compatibility is preserved

Precondition: existing callers use `caplog.clear()`, `caplog.records`,
`caplog.get_records(when)`, and `caplog.text`.

Postcondition: signatures and return shapes remain unchanged; no public
override or callsite must change.

Discharged by: `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-6: Machine-check caveat is explicit

Precondition: FVK proof artifacts are constructed in an environment where tests
and K tooling must not be run.

Postcondition: artifacts include exact commands and label the result
"constructed, not machine-checked"; no test removal is recommended.

Discharged by: `SPEC.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.
