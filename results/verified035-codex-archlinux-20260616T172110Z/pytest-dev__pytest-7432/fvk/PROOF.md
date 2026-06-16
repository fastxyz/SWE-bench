# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/pytest-skipping-spec.k`; the mini semantics are
in `fvk/mini-pytest-report.k`.

## P1: adequacy

`INTENT_SPEC.md` derives the target contract from the public issue rather than
from the current implementation. The pre-fix internal location is classified as
the symptom. `FORMAL_SPEC_ENGLISH.md` paraphrases each K claim, and
`SPEC_AUDIT.md` marks all four claims as matching the intent or a necessary
frame condition.

This discharges PO1.

## P2: marked skip plus runxfail

Initial symbolic state:

- `runxfail = true`
- `unexpected = false`
- `when = setup`
- `exc = skipExc`
- `skippedbymark = true`
- `outcome = skippedOutcome`
- `longrepr = internalSkip(R)`

Symbolic execution:

1. `makereport` rewrites to `checkUnexpected`.
2. `unexpected=false` rewrites to `checkXfailException`.
3. `runxfail=true` skips xfail-exception handling and rewrites to
   `checkXfailed`.
4. `runxfail=true` skips evaluated-xfail handling and rewrites to
   `checkMarkedSkip`.
5. `skippedbymark=true`, `outcome=skippedOutcome`, and
   `longrepr=internalSkip(R)` rewrite `longrepr` to `itemSkip(R)`.
6. `done` rewrites to `.K`.

The final observable matches claim C1: the skip reason is preserved and the
location class changes from internal skip site to item site. This discharges
PO2.

## P3: unmarked skip frame condition

For the same runxfail skipped-report path with `skippedbymark=false`, symbolic
execution reaches `checkMarkedSkip`, then the false-marker rule finishes
without changing `longrepr`.

This discharges PO5 and prevents the fix from broadening item-location rewrites
to runtime skips.

## P4: runxfail keeps xfail rewrites disabled

For `runxfail=true` and `exc=xfailExc`, symbolic execution uses the same
runxfail guard rule at `checkXfailException`, reaches `checkMarkedSkip`, and
does not set `wasxfail`. With `skippedbymark=false`, the report is left to the
base report machinery.

This discharges PO3.

## P5: non-runxfail xfail behavior is preserved

Under `runxfail=false`, V1's new branch predicates reduce as follows:

```text
not item.config.option.runxfail and call.excinfo and is_xfail_exception
==
True and call.excinfo and is_xfail_exception
==
call.excinfo and is_xfail_exception
```

and

```text
not item.config.option.runxfail and not rep.skipped and xfailed
==
True and not rep.skipped and xfailed
==
not rep.skipped and xfailed
```

These are exactly the pre-V1 predicates after the removed standalone
`runxfail` branch is known not to match. K claim C4 models the xfail-exception
case. This discharges PO4.

## P6: compatibility and residual risk

No public signatures or report shapes changed, discharging PO6.

The proof is partial over the modeled hook state. It does not prove pytest's
entire runtime, pluggy dispatch, or terminal rendering. Those are trusted
context from the issue and source inspection. The formal core keeps the
observable under audit, `longrepr`, so it distinguishes the failing pre-fix
state from the fixed state.

## Machine-check commands

These commands were not run because this task forbids executing K tooling:

```sh
kompile fvk/mini-pytest-report.k --backend haskell
kast --backend haskell fvk/pytest-skipping-spec.k
kprove fvk/pytest-skipping-spec.k
```

Expected result if the constructed claims and mini semantics are accepted by K:
`#Top`.

## Test recommendation

Do not remove tests based on this proof unless and until `kprove` returns
`#Top`. A public regression test for `pytest -rs --runxfail` with
`@pytest.mark.skip` or `skipif` would be covered by C1 after machine-checking,
but this task forbids editing tests.
