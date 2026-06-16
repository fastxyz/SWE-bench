# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run in this session.

## Commands To Machine-Check Later

```sh
kompile fvk/mini-pytest-unittest.k --backend haskell
kast --backend haskell fvk/pytest-unittest-teardown-spec.k
kprove fvk/pytest-unittest-teardown-spec.k
```

Expected machine-check result after successful setup: `#Top` for all claims.

## Proof Of PO-1 / SKIPPED-UNDER-PDB

Initial symbolic state:

- `<k> setup ~> runtest(true, false) ~> teardown </k>`
- `<explicit>` is arbitrary
- `<delayedCalls> = C`, with `C >= 0`

Step 1: `setup` rewrites `<explicit>` to `none`.

Step 2: `runtest(true, false)` rewrites to `maybeRecord(false)` because `--pdb`
is active but the abstract unittest execution does not call `tearDown`.

Step 3: `maybeRecord(false)` leaves `<explicit>` unchanged. It remains `none`.

Step 4: `teardown` rewrites to `maybeCall(none)`.

Step 5: `maybeCall(none)` performs no delayed call and leaves
`<delayedCalls> = C`.

Post-state: `<explicit> = none` and `<delayedCalls> = C`. This proves PO-1.

Discriminator check: the buggy predecessor would set `<explicit> = saved`
before Step 2. Then Step 4 would become `maybeCall(saved)` and Step 5 would set
`<delayedCalls> = C + 1`, contradicting PO-1. The model therefore proves the
behavior that distinguishes V1 from the regression.

## Proof Of PO-2 / REACHED-TEARDOWN-UNDER-PDB

Initial symbolic state:

- `<k> setup ~> runtest(true, true) ~> teardown </k>`
- `<explicit>` is arbitrary
- `<delayedCalls> = C`, with `C >= 0`

Step 1: `setup` rewrites `<explicit>` to `none`.

Step 2: `runtest(true, true)` rewrites to `maybeRecord(true)` because `--pdb`
is active and unittest reaches teardown.

Step 3: `maybeRecord(true)` sets `<explicit> = saved`, modeling the V1
replacement `tearDown` recording the original bound method.

Step 4: `teardown` rewrites to `maybeCall(saved)`.

Step 5: `maybeCall(saved)` clears `<explicit>` to `none` and increments
`<delayedCalls>` to `C + 1`.

Post-state: `<explicit> = none` and `<delayedCalls> = C + 1`. This proves PO-2.

## Proof Of PO-3 / NO-PDB-NO-DELAYED-CALL

Initial symbolic state:

- `<k> setup ~> runtest(false, UTCalls) ~> teardown </k>`
- `<explicit>` is arbitrary
- `<delayedCalls> = C`, with `C >= 0`

Step 1: `setup` rewrites `<explicit>` to `none`.

Step 2: `runtest(false, UTCalls)` does not install or call the delayed-teardown
recording rule. It leaves `<explicit> = none`.

Step 3: `teardown` rewrites to `maybeCall(none)`.

Step 4: `maybeCall(none)` performs no delayed call.

Post-state: `<explicit> = none` and `<delayedCalls> = C`. This proves PO-3.

## Compatibility And Adequacy

PO-4 is discharged by static source inspection in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: no public signature or protocol changes.

PO-5 is discharged by the adequacy gate in `fvk/SPEC_AUDIT.md`: the English
meaning of each claim matches the public intent and does not preserve the
reported buggy behavior.

## Test Redundancy Recommendation

No tests were modified or removed. Because this proof is not machine-checked,
no test should be removed on its basis in this session.

If the K commands later return `#Top`, a narrow unit test that only asserts the
abstract property "under `--pdb`, decorator-skipped unittest methods do not run
pytest-delayed `tearDown`" would be subsumed by PO-1. Integration tests covering
real pytest invocation, terminal reporting, PDB process interaction, traceback
formatting, and CPython unittest integration should be kept because the mini
semantics intentionally does not cover those layers.

## Residual Risk

This is a partial-correctness proof of the teardown-scheduling state machine.
It does not prove termination, complete pytest runner behavior, complete
CPython unittest semantics, PDB behavior, or terminal output. The trusted base
is the adequacy of the mini-K abstraction, K reachability logic, and a future
successful machine check.
