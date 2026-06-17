# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

## PO-01: Timeout-handler domain

Precondition: the Node timeout handler is reached with `parseInt(config.timeout, 10) = T`, `T > 0`, and no parse error.

Justification: the public issue uses `timeout: 5000`; the existing adapter already rejects unparseable timeouts before registering `req.setTimeout`.

Status: discharged by scope and existing guard.

## PO-02: Custom message wins

Claim: if `config.timeoutErrorMessage` is truthy and equals `M`, then the rejection message is `M`.

K claim: `someCustom(M)` reaches `rejected(customMsg(M), chooseCode(CL))`.

Source evidence: E-01, E-02, E-03, E-04, E-05.

Status: discharged by V1.

## PO-03: Default message preserved without a custom message

Claim: if `config.timeoutErrorMessage` is absent or falsy, the rejection message remains the generated default `timeout of <T>ms exceeded`.

K claim: `noCustom` reaches `rejected(defaultMsg(T), chooseCode(CL))`.

Source evidence: existing default behavior and XHR parity.

Status: discharged by V1.

## PO-04: Error-code frame condition

Claim: `transitional.clarifyTimeoutError` continues to select `ETIMEDOUT` when true and `ECONNABORTED` when false.

K claim: both message branches use `chooseCode(CL)`.

Status: discharged because V1 changes only the message expression passed to `AxiosError`.

## PO-05: Instance-config propagation

Claim: `axios.create({ timeoutErrorMessage: M })` preserves `timeoutErrorMessage` through request config merging to the adapter.

Source fact: `mergeConfig` preserves unknown defined scalar keys through `mergeDeepProperties` when a key is present in either config object.

Status: discharged by static code inspection. The `timeoutMessage` merge-map key is suspicious but not behaviorally blocking.

## PO-06: Public compatibility

Claim: no public API, option name, function signature, adapter dispatch shape, or package entry point is changed.

Status: discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-07: SUSPECT visible test does not override public issue intent

Claim: the visible HTTP unit test assertion expecting the default message for a custom-message config is stale legacy evidence and must not define the spec.

Status: discharged by the FVK intent-evidence rule and Finding F-02.

## PO-08: Machine-check commands

Commands to run later, not executed in this environment:

```sh
kompile fvk/mini-axios-timeout.k --backend haskell
kast --backend haskell fvk/axios-timeout-spec.k
kprove fvk/axios-timeout-spec.k
```

Expected machine-check result if the mini-semantics and claims parse as written: `#Top`.

Status: constructed, not machine-checked.
