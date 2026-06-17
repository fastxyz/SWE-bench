# Formal Spec English

The K core models only the timeout-handler decision that affects the reported observable: the rejected AxiosError message and error code. It abstracts the rendered default text as `defaultMsg(T)` and a custom string as `customMsg(M)` so the proof can distinguish the failing pre-fix behavior from the intended one.

1. Claim 1: from a timeout-handler state with positive parsed timeout `T`, truthy custom timeout message `M`, and `clarifyTimeoutError` flag `CL`, executing `handleTimeout` reaches a state where the request is aborted and the rejection is `rejected(customMsg(M), chooseCode(CL))`.
2. Claim 2: from the same state but without a custom timeout message, executing `handleTimeout` reaches a state where the request is aborted and the rejection is `rejected(defaultMsg(T), chooseCode(CL))`.
3. `chooseCode(true)` is `ETIMEDOUT`; `chooseCode(false)` is `ECONNABORTED`.
4. There are no loops or recursive calls in the modeled unit, so there is no circularity obligation.
