# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The K core is in `fvk/mini-caplog.k`; the claims are in
`fvk/caplog-clear-spec.k`.

- `CLEAR-CURRENT` proves PO-1 and PO-4.
- `CLEAR-THEN-EMIT` proves PO-2.
- `BEGIN-PHASE-PRESERVES-PREVIOUS` proves PO-3.

## Proof Sketch

### CLEAR-CURRENT

The initial state has active phase `P`, handler reference `R`, stash entry
`P |-> R`, and heap entry `R |-> L`.

Symbolic execution applies the `caplogClear` rule. That rule rewrites only the
contents stored at heap entry `R`, changing `L` to `.List`, and rewrites stream
content to `.List`. It does not rewrite `<handlerRef>` or the stash map.

By framing, the current phase stash entry remains `P |-> R` and the handler
reference remains `R`. Therefore `caplog.records` and `get_records(P)` still
denote the same list object, whose contents are empty.

### CLEAR-THEN-EMIT

By transitivity, first apply the `CLEAR-CURRENT` reasoning to reach a state with
heap entry `R |-> .List` and stash entry `P |-> R`. Then symbolically execute
`emit(B)`.

The `emit` rule reads the unchanged handler reference `R` and appends `B` to
heap entry `R`, producing `R |-> ListItem(B)`. Because the stash still maps `P`
to `R`, the later record is visible through both `caplog.records` and
`get_records(P)`.

### BEGIN-PHASE-PRESERVES-PREVIOUS

The initial state has setup stash reference `RS` and heap entry
`RS |-> SETUP`. `beginPhase(call)` models `_runtest_for`: allocate fresh
reference `RC`, set handler records to `RC`, clear stream content, and store
`call |-> RC`.

The rule updates heap only at fresh key `RC` and does not rewrite the existing
`RS` entry. By framing, `setup |-> RS` and `RS |-> SETUP` remain unchanged.
This discharges the obligation that `reset()` must replace the current list for
phase transitions instead of clearing the old phase list in place.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` states the same obligations as INT-1 through INT-5,
and `SPEC_AUDIT.md` marks all formal items pass. The proof does not rely on a
legacy behavior contradicted by the issue. `PUBLIC_COMPATIBILITY_AUDIT.md`
finds no public API incompatibility.

## Exact Machine-Check Commands

These commands are provided for a later environment with K installed. They were
not executed here.

```sh
kompile fvk/mini-caplog.k --backend haskell
kast --backend haskell fvk/caplog-clear-spec.k
kprove fvk/caplog-clear-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for all claims.

## Test Guidance

No tests were read as an oracle, no tests were modified, and no test deletion is
recommended. If machine-checking later succeeds, ordinary point tests for
same-phase `clear()` aliasing may be considered proof-subsumed, but integration
tests for pytest phase behavior should remain.
