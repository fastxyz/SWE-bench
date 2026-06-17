# ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

No additional production source edit is justified by the FVK audit. V1 satisfies PO-02, preserves PO-03 and PO-04, and does not introduce a public compatibility issue under PO-06.

## Do Not Change In This Benchmark Pass

- Do not edit tests. Finding F-02 identifies a stale visible assertion, but the task explicitly forbids test modification.
- Do not edit `repo/lib/core/mergeConfig.js` for this issue. Finding F-03 records the suspicious `timeoutMessage` key, but PO-05 shows `timeoutErrorMessage` still propagates through the default merge path.
- Do not update `repo/dist/`. Finding F-05 shows the Node defect path is `repo/lib/adapters/http.js`, and the browser/XHR path already has the intended behavior.

## Suggested Normal-Project Follow-Ups

1. Update or add public tests so the Node HTTP adapter custom-message case asserts the custom string.
2. Consider a separate cleanup that replaces the unused-looking `timeoutMessage` merge-map key with `timeoutErrorMessage`, after checking compatibility expectations.
3. Run the machine-check commands in PO-08 if K tooling is available.
