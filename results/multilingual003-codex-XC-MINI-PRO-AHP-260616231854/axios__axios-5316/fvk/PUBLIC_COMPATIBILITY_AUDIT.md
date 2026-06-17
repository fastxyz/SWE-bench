# Public Compatibility Audit

Status: constructed from public package metadata and source inspection; no tests or build commands were run.

## Changed public or producer/consumer paths

| Path | Public consumer | V1 status | V2 status |
|---|---|---|---|
| `repo/lib/adapters/http.js` | ESM source entry through `repo/index.js` and in-repo source imports. | Fixed. | Fixed. |
| `repo/lib/helpers/formDataToStream.js` | Internal helper imported by `lib/adapters/http.js`. | New internal helper; no public API. | Unchanged. |
| `repo/dist/node/axios.cjs` | `require('axios')` via package exports, matching the issue reproduction. | Stale; still had unsupported-object branch only. | Fixed by mirroring helper and adapter branch. |

## Compatibility conclusion

The source helper is internal and does not change public API shape. The legacy `form-data` package branch remains first in both source and CJS bundle. The manual `dist/node/axios.cjs` mirror is justified because the benchmark forbids running the build, while public evidence uses the CJS package path.
