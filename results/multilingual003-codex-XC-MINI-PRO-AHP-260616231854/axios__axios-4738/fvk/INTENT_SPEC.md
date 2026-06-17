# Intent Spec

Status: constructed from public evidence only.

1. For a Node.js request timeout with a truthy `config.timeoutErrorMessage`, Axios must reject with an `AxiosError` whose message is that configured string.
2. For a Node.js request timeout without a truthy `config.timeoutErrorMessage`, Axios must preserve the existing generated timeout message, `timeout of <timeout>ms exceeded`, for positive timeout values that reach the timeout handler.
3. The `transitional.clarifyTimeoutError` option still controls only the error code: `ETIMEDOUT` when true, `ECONNABORTED` when false.
4. The timeout handler still aborts the request and still rejects with the original `config` and request object.
5. The repair must not change public API shape or require callers to use a different option name.
