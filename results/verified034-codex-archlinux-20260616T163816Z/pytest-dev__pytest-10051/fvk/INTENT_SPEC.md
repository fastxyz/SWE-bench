# Intent Spec

This is the intent-only English spec derived before accepting the V1
implementation as correct.

## INT-1: Active phase records stay coupled across clear

Public evidence: the issue says "`caplog.get_records()` gets decoupled from
actual caplog records when `caplog.clear()` is called" and says this is the
bug.

Obligation: during an active phase, `caplog.clear()` must not detach
`caplog.get_records(when)` from `caplog.records`.

## INT-2: Clear affects both current views

Public evidence: the reproduction defines `verify_consistency()` as
`caplog.get_records("call") == caplog.records` and expects it to hold after
`caplog.clear()`.

Obligation: immediately after clearing, the current phase's `get_records(when)`
view and `caplog.records` view are both empty.

## INT-3: Records emitted after clear are visible through both views

Public evidence: the issue says after `caplog.clear()` the `get_records()` view
"does not get new records" and identifies that as part of the bug.

Obligation: records emitted after `caplog.clear()` in the same phase must be
visible through both `caplog.records` and `caplog.get_records(when)`.

## INT-4: Phase records remain phase-specific

Public evidence: `LogCaptureFixture.get_records` documents `when` as one of
`"setup"`, `"call"`, and `"teardown"` and returns "the logging records at the
given stage".

Obligation: resetting capture for a later phase must not erase records already
stored for an earlier phase.

## INT-5: Clear also clears formatted text

Public evidence: the `caplog` fixture docs say `caplog.clear()` clears captured
records and the formatted log output string.

Obligation: `caplog.clear()` leaves `caplog.text` empty until another record is
emitted.
