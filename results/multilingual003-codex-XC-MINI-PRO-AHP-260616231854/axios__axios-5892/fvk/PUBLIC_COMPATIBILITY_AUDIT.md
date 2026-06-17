# Public Compatibility Audit

Status: constructed, not machine-checked.

| ID | Surface | Audit result |
|---|---|---|
| C1 | `repo/lib/adapters/http.js` public adapter behavior | No public signature or config shape changed. Only the value compared by the existing switch is normalized. |
| C2 | `repo/dist/node/axios.cjs` CommonJS package build | Mirrored the source adapter expression so `require('axios')` receives the same behavior. |
| C3 | Browser/XHR adapters | Not touched. The issue names adapter `http`, and browser decompression is not controlled by this Node branch. |
| C4 | Response headers after decoding | Existing deletion behavior is preserved for decode branches and no-body branches. |
| C5 | Tests | No test files modified, as required. |
