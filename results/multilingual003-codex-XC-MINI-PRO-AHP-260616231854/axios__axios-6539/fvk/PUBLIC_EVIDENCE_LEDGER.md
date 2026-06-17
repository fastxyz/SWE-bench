# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | `benchmark/PROBLEM.md` | "Server-Side Request Forgery Vulnerability" | Audit the Node/server-side request path, not only browser adapters. | Encoded in SPEC.md and claims. |
| E-002 | `benchmark/PROBLEM.md` | "requests for path relative URLS gets processed as protocol relative URLs" | Inputs that become protocol-relative after path construction must not be sent as external-host requests. | Encoded in O-001/O-002. |
| E-003 | `benchmark/PROBLEM.md` | "Given protocol-relative URLs are not relevant server-side as there is no protocol to be relative to, the expected result would be an error." | Server-side protocol-relative targets must reject before request creation. | Encoded in O-001. |
| E-004 | `benchmark/PROBLEM.md` | `new URL(fullPath, 'http://localhost')` can prepend `http:` to `//google.com`. | The fix must be before the fallback URL parse supplies a protocol. | Encoded in O-002. |
| E-005 | `repo/package.json` | CommonJS default export path is `./dist/node/axios.cjs`; ESM default path is `./index.js`. | Patch source adapter and checked-in CommonJS Node bundle when no build step is available. | Encoded in O-005. |
| E-006 | `repo/lib/core/buildFullPath.js` | `buildFullPath` returns requested absolute URLs untouched. | The guard must run after `buildFullPath`, because protocol-relative requested URLs bypass `baseURL`. | Encoded in O-002. |
| E-007 | implementation and URL parsing model | The URL fallback parser can treat paired slash/backslash authority spellings after leading C0/space trimming as authority form. | V1's literal `//` guard is too narrow; reject any leading C0/space plus two `/` or `\` separators. | Finding F-001, fixed in V2. |

