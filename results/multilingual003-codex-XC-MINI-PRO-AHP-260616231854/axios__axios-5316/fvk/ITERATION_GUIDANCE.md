# ITERATION GUIDANCE

Status: guidance after the FVK audit and V2 repair.

## Code Decisions

1. Keep the V1 source helper and source adapter branch.
   - Justification: Findings F1 and proof obligations PO1-PO4 show the helper discharges the Node 18 `FormData` intent.

2. Keep the legacy `form-data` package branch first.
   - Justification: PO6 and formal claim 2 preserve existing package behavior.

3. Add the same fix to `repo/dist/node/axios.cjs`.
   - Justification: Finding F2 and PO5 show V1 was incomplete for the public `require('axios')` reproduction path.

4. Do not edit browser bundles or XHR adapter code.
   - Justification: The issue is Node-specific, and browser FormData behavior is already handled by the XHR adapter. No public evidence requires browser bundle changes for this issue.

5. Do not edit tests.
   - Justification: The task forbids test-file edits, and the proof is constructed but not machine-checked.

## Follow-Up Recommendations

- In a normal development environment, run the generated FVK commands:

```sh
kompile fvk/mini-js-formdata.k --backend haskell
kast --backend haskell fvk/axios-formdata-spec.k
kprove fvk/axios-formdata-spec.k
```

- Run the project build so generated bundles are produced from `lib/` rather than manually mirrored.
- Add public tests in the real project for:
  - Node 18 global `FormData` with string fields through the HTTP adapter;
  - Node 18 global `FormData` through `require('axios')`;
  - preservation of legacy `form-data` package behavior.

No tests were run in this benchmark session, by instruction.
