# Public Compatibility Audit

Changed public symbols: none.

Changed internal behavior:

- `repo/lib/adapters/http.js` timeout handler now reads the existing public config option `timeoutErrorMessage`.
- No function signature, exported type, adapter interface, or public option name changed.
- Existing timeout parse error behavior is unchanged.
- Existing fallback timeout message behavior is unchanged when no truthy custom message is supplied.
- Existing `transitional.clarifyTimeoutError` error-code behavior is unchanged.

Public callsites:

- `repo/index.js` exports `./lib/axios`, which dispatches to `repo/lib/adapters/http.js` in Node.
- Browser mapping in `repo/package.json` replaces the HTTP adapter with the XHR adapter, which already honors `timeoutErrorMessage`.

Compatibility verdict: pass. No source edit beyond V1 is required for compatibility.
