# Baseline Notes

## Root Cause

The Node HTTP adapter builds a `fullPath` with `buildFullPath(config.baseURL, config.url)` and then parses it with `new URL(fullPath, 'http://localhost')`. `buildFullPath` treats protocol-relative URLs such as `//google.com` as absolute, so it does not prepend `baseURL`. The Node `URL` constructor then resolves the protocol-relative value against the fallback base and turns it into an `http:` request to the attacker-controlled host.

That fallback base is needed for ordinary relative paths in Node, but it should not supply a protocol for protocol-relative request targets because there is no browser document protocol in the server-side adapter.

## Changed Files

- `repo/lib/adapters/http.js`: added a protocol-relative URL guard after `buildFullPath` and before `new URL(...)`. Requests whose resolved path begins with `//`, allowing leading whitespace that the URL parser would trim, now reject with `AxiosError.ERR_INVALID_URL` instead of being interpreted as `http://...`.
- `repo/dist/node/axios.cjs`: applied the same guard to the checked-in CommonJS Node bundle because `package.json` routes `require('axios')` through this file and the benchmark environment does not allow running the build step to regenerate it.

## Assumptions

- The issue is server-side specific. Browser protocol-relative URLs can be meaningful because browsers have an ambient page protocol, but the Node HTTP adapter does not.
- Rejecting protocol-relative Node requests is acceptable and matches the issue's expected behavior of raising an error rather than silently using `http://localhost` as a protocol source.
- Hidden checks may import axios through either the ESM source path or the CommonJS package export, so both the source adapter and the checked-in Node bundle need the same change.

## Alternatives Considered

- Changing `isAbsoluteURL` so `//host` is no longer absolute was rejected because that helper is shared by browser-facing URL resolution and would alter broader documented behavior.
- Combining `baseURL` with protocol-relative URLs was rejected because it would change general URL classification semantics and would not address direct server-side requests to `//host` without a `baseURL`.
- Removing the fallback base from `new URL(...)` was rejected because the fallback exists to support ordinary relative paths in Node and removing it would regress valid relative requests.

## Verification

Per the benchmark instructions, I did not run tests or execute project code.
