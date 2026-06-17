# Baseline Notes

## Root cause

The Node HTTP adapter ignored `config.timeoutErrorMessage` when a request timed out. Its timeout handler always constructed the AxiosError with `timeout of <timeout>ms exceeded`, unlike the XHR adapter, which first checks `config.timeoutErrorMessage` and uses the configured custom message when present.

The issue reproduces with `axios.create({ timeoutErrorMessage: ... })` because the instance config reaches the adapter, but the Node timeout branch never reads that option before rejecting.

## Files changed

- `repo/lib/adapters/http.js`: Updated the `req.setTimeout` rejection path to select `config.timeoutErrorMessage` when provided, falling back to the existing default timeout message otherwise. The timeout parsing, request abort behavior, and `clarifyTimeoutError` error-code selection were left unchanged.

## Assumptions and alternatives considered

- I assumed the intended behavior is parity with the existing XHR adapter: a truthy `timeoutErrorMessage` overrides the generated timeout message, while an absent or falsy value keeps the default message.
- I considered changing `repo/lib/core/mergeConfig.js` because it contains a `timeoutMessage` key rather than `timeoutErrorMessage`. I rejected that as unnecessary for this bug: unknown scalar config keys are already preserved by the default merge path, so the repro's `timeoutErrorMessage` is available to the adapter.
- I did not modify generated browser bundles under `repo/dist/` because the reported failure is in Node.js and the package entry point uses `repo/lib/axios.js`, which dispatches to `repo/lib/adapters/http.js` in Node.
- I did not modify tests, per the benchmark instructions.
