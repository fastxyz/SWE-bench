# Intent Spec

Status: constructed, not machine-checked.

## Required Behaviors

I-001: In the server-side Node HTTP adapter, a request target that is protocol-relative must not be resolved against the fallback base URL and must not cause a network request to the authority in that target.

I-002: The expected server-side behavior for a protocol-relative request target is an error, because there is no ambient browser/document protocol on the server.

I-003: Ordinary relative paths still need the `http://localhost` fallback base so Node can parse them without regressing the relative-path support introduced for the HTTP adapter.

I-004: Browser-facing protocol-relative behavior is not in scope for this server-side vulnerability fix.

I-005: CommonJS package consumers must receive the same Node HTTP adapter behavior as ESM/source consumers because `package.json` routes `require('axios')` through `dist/node/axios.cjs`.

