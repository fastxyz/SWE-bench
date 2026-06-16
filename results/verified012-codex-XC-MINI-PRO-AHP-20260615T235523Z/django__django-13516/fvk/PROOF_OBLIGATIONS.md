# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Flush delegates when the wrapped stream supports flush

Claim: `FLUSH-DELEGATES` in `outputwrapper-spec.k`.

For any stream state `stream(true, B, V, F, R)`, executing `wrapper(out).flush()`
rewrites the state to `stream(true, 0, V + B, F + 1, R)` and returns `R`.

Evidence: E1, E4, E5, E7.

Discharge status: constructed proof closes by applying the flush-delegation rule in
`mini-management-output.k`.

## PO-2: Flush is compatible with streams without flush

Claim: `FLUSH-NO-METHOD-NOOP` in `outputwrapper-spec.k`.

For any stream state `stream(false, B, V, F, R)`, executing `wrapper(out).flush()`
returns `none` and leaves the stream state unchanged.

Evidence: E6, E7, INT-5.

Discharge status: constructed proof closes by applying the no-flush compatibility rule.

## PO-3: Partial write followed by flush makes progress visible

Claim: `PARTIAL-WRITE-THEN-FLUSH` in `outputwrapper-spec.k`.

For any stream with `flush`, executing `wrapper(out).writePartial(N)` followed by
`wrapper(out).flush()` moves the prior buffer plus `N` new output units into visible
output, empties the buffer, increments the flush count, and returns the underlying
flush result.

Evidence: E2, E3, E7.

Discharge status: constructed proof closes by transitivity: first apply the partial
write rule, then instantiate PO-1 on the updated buffer.

## PO-4: Frame conditions for unaffected management output behavior

Claim: source-level frame condition, represented in `FORMAL_SPEC_ENGLISH.md` and
`PUBLIC_COMPATIBILITY_AUDIT.md`.

V1 must not change write formatting, style handling, line-ending behavior, construction
of `BaseCommand.stdout`/`stderr`, or replacement of custom streams passed through
`call_command`.

Evidence: E4, E6.

Discharge status: source diff review confirms only `OutputWrapper.flush()` was added.

## PO-5: Adequacy gate

Claim: every formal-English statement matches an intent-only obligation.

Evidence: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`.

Discharge status: pass. No claim preserves the issue's reported no-op flush behavior.

## PO-6: Reproducible machine-check commands

Commands to run later, not executed in this session:

```sh
cd fvk
kompile mini-management-output.k --backend haskell
kast --backend haskell outputwrapper-spec.k
kprove outputwrapper-spec.k
```

Expected machine-check outcome: `kprove` returns `#Top` for all three claims. This
expectation is constructed, not machine-checked.
