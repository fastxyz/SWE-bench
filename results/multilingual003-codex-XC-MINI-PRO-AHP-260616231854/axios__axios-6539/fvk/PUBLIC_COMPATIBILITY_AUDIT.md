# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Surface

- No public function signature, exported type, method name, request config field, or adapter selection API changed.
- Runtime behavior changed only for Node HTTP adapter request targets whose post-`buildFullPath` value begins with optional C0/space characters and then two authority separators (`/` or `\`).

## Callsite And Bundle Coverage

- ESM/default source consumers reach `repo/index.js` and `repo/lib/adapters/http.js`; patched.
- CommonJS package consumers reach `repo/dist/node/axios.cjs`; patched because the benchmark forbids running a build.
- Browser bundle behavior is intentionally unchanged; the vulnerability and intent are server-side.

## Compatibility Verdict

Compatible with intended public API. The behavior change is a security rejection for invalid server-side protocol-relative targets and does not alter adapter signatures or ordinary relative-path parsing.

