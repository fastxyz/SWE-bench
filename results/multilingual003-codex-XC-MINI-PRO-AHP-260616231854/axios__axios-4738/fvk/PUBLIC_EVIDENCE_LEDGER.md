# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-01 | `benchmark/PROBLEM.md` | "timeoutErrorMessage property in config not work with Node.js" | The Node adapter must consume `config.timeoutErrorMessage`. | Encoded by PO-02 and claim 1. |
| E-02 | `benchmark/PROBLEM.md` | "expected custom error message, got 'timeout of 5000ms exceeded'" | A truthy custom message wins over the default timeout text. | Encoded by PO-02 and claim 1. |
| E-03 | `benchmark/PROBLEM.md` | Repro uses `axios.create({ timeout: 5000, timeoutErrorMessage: 'Custom Timeout Error Message' })`. | Instance defaults must reach the timeout handler. | Audited by PO-05. |
| E-04 | `repo/index.d.ts` | `timeoutErrorMessage?: string;` | The public option name is `timeoutErrorMessage`. | Supports PO-01/PO-02. |
| E-05 | `repo/lib/adapters/xhr.js` | XHR timeout path checks `config.timeoutErrorMessage`. | Browser behavior supplies parity evidence for Node. | Supports PO-02/PO-03. |
| E-06 | `repo/test/unit/adapters/http.js` | Test title says "should respect the timeoutErrorMessage property" but assertion expects default text. | This is a SUSPECT legacy assertion because it conflicts with E-01/E-02. | Finding F-02. |
| E-07 | `repo/package.json` | `"main": "index.js"` and browser field maps HTTP adapter to XHR. | Node package entry uses `lib/adapters/http.js`; browser bundle/dist is not the Node defect path. | Finding F-05. |
