# FINDINGS

Status: constructed, not machine-checked. Findings do not depend on executing tests.

## F-01: V1 discharges the reported Node timeout-message bug

Input: Node timeout with parsed timeout `T = 5000` and truthy `config.timeoutErrorMessage = "Custom Timeout Error Message"`.

Observed pre-fix behavior from the issue: `timeout of 5000ms exceeded`.

Expected by public intent: `Custom Timeout Error Message`.

V1 behavior by static source inspection: `var timeoutErrorMessage = config.timeoutErrorMessage || 'timeout of ' + timeout + 'ms exceeded';` followed by `new AxiosError(timeoutErrorMessage, ...)`, so the custom message is used.

Classification: fixed code bug.

Related proof obligations: PO-01, PO-02.

## F-02: Visible HTTP adapter test assertion is SUSPECT legacy behavior

Input: `repo/test/unit/adapters/http.js` test named `should respect the timeoutErrorMessage property` sets `timeoutErrorMessage: 'oops, timeout'`.

Observed assertion in visible test: `error.message` equals `timeout of 250ms exceeded`.

Expected by public issue and test title: `oops, timeout`.

Classification: stale or legacy public test evidence, not an oracle. The benchmark forbids modifying tests, so no test file was changed.

Related proof obligations: PO-02, PO-07.

## F-03: `mergeConfig.js` contains a suspicious `timeoutMessage` key, but it does not block this fix

Input: instance config from the issue, `axios.create({ timeoutErrorMessage: "Custom Timeout Error Message" })`.

Observed code: `mergeConfig` has a merge-map entry for `timeoutMessage`, not `timeoutErrorMessage`.

Expected by public issue: the instance default should still reach the adapter.

Static analysis: unlisted scalar keys use `mergeDeepProperties`, which preserves defined keys from either config object. Therefore `timeoutErrorMessage` is retained despite the typo-like `timeoutMessage` entry.

Classification: suspicious non-blocking cleanup candidate, not a required source change for this issue.

Related proof obligations: PO-05.

## F-04: Empty-string custom timeout messages are ambiguous and intentionally not changed

Input: `config.timeoutErrorMessage = ""`.

Observed V1 behavior: falls back to the default timeout message because JavaScript `||` treats the empty string as falsy.

Expected by public evidence: ambiguous. The issue uses a non-empty custom message, and the XHR adapter already uses a truthy check.

Classification: underspecified edge case. V1 follows existing XHR parity; no source change is justified by public intent.

Related proof obligations: PO-03.

## F-05: Generated browser bundles are not the Node defect path

Input: Node package import through `repo/index.js`.

Observed public entry: `package.json` sets `"main": "index.js"`; `index.js` requires `./lib/axios`; Node dispatches to `lib/adapters/http.js`.

Expected by issue: Node adapter behavior is fixed.

Classification: no action. `repo/dist/` is a generated browser distribution path and the browser/XHR timeout path already supports `timeoutErrorMessage`.

Related proof obligations: PO-06.

## F-06: Proof is constructed only

Input: FVK proof artifacts and commands.

Observed: no `kompile`, `kast`, `kprove`, tests, Python, or project code were executed.

Expected by task: commands are written into artifacts and reasoned about instead of executed.

Classification: honesty-gate residual risk. Keep tests; no test-redundancy removal is recommended.

Related proof obligations: PO-08.
