# PROOF

Status: constructed, not machine-checked.

## What Is Proved

For the modeled Node timeout-handler branch, if a positive parsed timeout `T` reaches `handleRequestTimeout`:

1. With a truthy custom timeout message `M`, the rejection carries `customMsg(M)`.
2. Without a truthy custom timeout message, the rejection carries `defaultMsg(T)`.
3. The error code is still selected from `transitional.clarifyTimeoutError`.
4. The request is still aborted before the rejection is produced.

## Symbolic Proof Sketch

The mini-semantics has one executable statement, `handleTimeout`. Its rule rewrites:

```k
<aborted> false => true </aborted>
<rejected> none => rejected(chooseMsg(T, C), chooseCode(CL)) </rejected>
```

under the precondition `T >Int 0`.

For the custom-message claim, instantiate `C = someCustom(M)`. The simplification rule

```k
chooseMsg(T, someCustom(M)) => customMsg(M)
```

reduces the rejection to `rejected(customMsg(M), chooseCode(CL))`, which is exactly the post-state in the claim.

For the no-custom claim, instantiate `C = noCustom`. The simplification rule

```k
chooseMsg(T, noCustom) => defaultMsg(T)
```

reduces the rejection to `rejected(defaultMsg(T), chooseCode(CL))`, which is exactly the post-state in the claim.

For both claims, `chooseCode(true) => ETIMEDOUT` and `chooseCode(false) => ECONNABORTED`, preserving the existing `clarifyTimeoutError` frame condition.

There are no loops or recursive calls in this modeled unit, so no circularity proof is required. The proof is direct symbolic execution plus function simplification.

## Connection To V1 Source

The V1 source line

```js
var timeoutErrorMessage = config.timeoutErrorMessage || 'timeout of ' + timeout + 'ms exceeded';
```

implements `chooseMsg(T, C)`: a truthy configured value maps to `customMsg(M)`, while absent or falsy values map to `defaultMsg(T)`.

The subsequent `new AxiosError(timeoutErrorMessage, transitional.clarifyTimeoutError ? AxiosError.ETIMEDOUT : AxiosError.ECONNABORTED, config, req)` implements the `rejected(chooseMsg(T, C), chooseCode(CL))` post-state.

The pre-fix code would correspond to always producing `defaultMsg(T)` in the custom branch, contradicting PO-02 and Finding F-01.

## Adequacy And Compatibility

`fvk/SPEC_AUDIT.md` marks the custom and default branches as pass. The only ambiguity is empty-string custom messages, which are outside the concrete issue and are intentionally left aligned with the XHR adapter's truthy behavior.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public API or dispatch incompatibility.

## Test Recommendation

No tests should be removed. The proof is constructed, not machine-checked, and the task forbids test edits. A normal project follow-up would update the stale visible HTTP adapter assertion described in F-02, but this benchmark repair leaves tests untouched.

## Reproduce The Machine Check Later

These commands were not executed:

```sh
kompile fvk/mini-axios-timeout.k --backend haskell
kast --backend haskell fvk/axios-timeout-spec.k
kprove fvk/axios-timeout-spec.k
```

Expected result after a successful machine check: `#Top`.
