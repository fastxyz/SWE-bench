# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no missed production-code obligation for the reported Node timeout-message issue.

## Trace To Findings And Proof Obligations

- The decision to keep the V1 source line in `repo/lib/adapters/http.js` is justified by Finding F-01 and obligations PO-01/PO-02: the custom-message branch now rejects with `config.timeoutErrorMessage` for the issue's in-domain Node timeout case.
- The decision not to alter the fallback behavior is justified by PO-03 and Finding F-04: absent or falsy custom messages remain on the default timeout message, matching the existing XHR truthy check.
- The decision not to touch `transitional.clarifyTimeoutError` behavior is justified by PO-04: V1 changes only the message expression and leaves the error-code selection intact.
- The decision not to patch `repo/lib/core/mergeConfig.js` is justified by Finding F-03 and PO-05: although `timeoutMessage` looks suspicious, `timeoutErrorMessage` is still preserved by the default merge path for unknown scalar config keys.
- The decision not to update tests is required by the benchmark and recorded in Finding F-02 and PO-07: the visible HTTP adapter assertion is SUSPECT legacy evidence, but test edits are forbidden.
- The decision not to update generated `repo/dist/` artifacts is justified by Finding F-05 and PO-06: the Node package path reaches `repo/lib/adapters/http.js`, while the browser/XHR path already supports `timeoutErrorMessage`.
- The decision not to claim machine-checked proof or remove tests is justified by Finding F-06 and PO-08: the FVK commands are documented but were not executed.

## Source Changes In This FVK Pass

No source files under `repo/` were changed during the FVK pass. The only new files are FVK artifacts under `fvk/` and this report.
