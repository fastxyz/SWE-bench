# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `axios__axios-4738`: the Node HTTP adapter timeout path in `repo/lib/adapters/http.js`. The modeled unit is the `req.setTimeout(... handleRequestTimeout ...)` branch after `config.timeout` has been parsed to a positive integer and the timeout event fires. There are no loops in the modeled unit.

The formal core is in:

- `fvk/mini-axios-timeout.k`
- `fvk/axios-timeout-spec.k`

## Contract

For every positive parsed timeout `T` and every Node timeout event:

1. If `config.timeoutErrorMessage` is truthy, the rejected `AxiosError.message` must be exactly `config.timeoutErrorMessage`.
2. If `config.timeoutErrorMessage` is absent or falsy, the rejected `AxiosError.message` must remain `timeout of <T>ms exceeded`.
3. `transitional.clarifyTimeoutError` continues to choose only the error code: `ETIMEDOUT` when true, `ECONNABORTED` when false.
4. The request abort behavior and the use of the original `config` and request object are frame conditions.

## Intent Ledger

The full public ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The decisive entries are:

- E-01/E-02: the issue requires a custom timeout message in Node instead of `timeout of 5000ms exceeded`.
- E-03: the repro sets the option on an Axios instance, so config propagation to the adapter is in scope.
- E-05: the XHR adapter already uses `config.timeoutErrorMessage`, making Node parity an intent-compatible interpretation.
- E-06: the visible test assertion expecting the default message is SUSPECT because it contradicts the issue and its own test title.

## Formal Abstraction

The K model abstracts concrete strings as message constructors:

- `customMsg(M)` represents a configured custom message string.
- `defaultMsg(T)` represents the generated string `timeout of <T>ms exceeded`.

This abstraction is property-complete for the defect because it distinguishes the failing pre-fix result, `defaultMsg(T)`, from the required result, `customMsg(M)`.

## Adequacy

The English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the intent items in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` records one ambiguity, empty-string custom messages, and marks it non-blocking because the public issue uses a non-empty string and the XHR adapter's existing behavior is truthy-based.

## Compatibility

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no changed public symbol, signature, export, option name, or dispatch shape. V1 only changes the value passed into `AxiosError` on the Node timeout branch.
