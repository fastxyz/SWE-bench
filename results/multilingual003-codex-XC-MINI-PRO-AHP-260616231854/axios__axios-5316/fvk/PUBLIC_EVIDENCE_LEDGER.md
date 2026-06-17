# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "Using FormData type from Node.js 18 global leads to an error." | Node 18 global `FormData` is in-domain input for the Node adapter. | Encoded in `SPEC.md` and `axios-formdata-spec.k`. |
| E2 | `benchmark/PROBLEM.md` | Error text: `Data after transformation must be a string, an ArrayBuffer, a Buffer, or a Stream` | That error is the reported bug for Node 18 `FormData`; it must not be preserved for this input class. | Finding F1, discharged by PO1-PO4. |
| E3 | `benchmark/PROBLEM.md` | Reproduction uses `const axios = require('axios')` and `const FormData = global.FormData`. | The CommonJS public package path must support the same behavior. | Finding F2, discharged by PO5. |
| E4 | `benchmark/PROBLEM.md` | Request header includes `'Content-Type': 'multipart/form-data'`. | The fixed path must supply a usable multipart boundary/header set rather than sending a boundary-less object. | Discharged by PO2 and PO3. |
| E5 | `repo/lib/adapters/http.js` before V1 | Existing branch checks `utils.isFormData(data) && utils.isFunction(data.getHeaders)`. | Legacy `form-data` package support must remain first and unchanged. | Discharged by PO6. |
| E6 | `repo/package.json` | `exports["."].default.require` points to `./dist/node/axios.cjs`. | Source-only V1 did not fully cover the public CJS reproduction in this workspace. | Resolved by V2 bundle mirror. |
