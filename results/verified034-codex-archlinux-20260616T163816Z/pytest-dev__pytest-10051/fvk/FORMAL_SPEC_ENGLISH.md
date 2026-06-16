# Formal Spec English

All claims are constructed, not machine-checked.

## CLEAR-CURRENT

For any active phase `P`, if the handler's `records` field and
`item.stash[caplog_records_key][P]` refer to the same list object `R`, then
executing `caplog.clear()` keeps the handler reference equal to `R`, keeps the
phase stash reference equal to `R`, mutates the list object `R` to the empty
list, and clears the formatted text content.

## CLEAR-THEN-EMIT

For any active phase `P`, if `caplog.clear()` is followed by an emitted record
`B`, the handler and the current phase stash still refer to the same list object
`R`, and the contents of `R` are exactly `[B]`.

## BEGIN-PHASE-PRESERVES-PREVIOUS

When capture begins for the `call` phase after `setup` records have already
been stored under a distinct list object `RS`, phase setup allocates a fresh
current records object `RC`, stores `RC` for `call`, and leaves the `setup`
stash entry and its list contents unchanged.

## Frame Conditions

`caplog.clear()` does not change the handler object, the active phase key, or
non-current phase stash entries. The formal text obligation is about the text
content returned through `caplog.text`, not identity of the private `StringIO`
object.
