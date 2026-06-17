# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass verifies the Node HTTP adapter decision immediately after:

```js
const fullPath = buildFullPath(config.baseURL, config.url);
```

The observable decision is whether `fullPath` is rejected as invalid before `new URL(fullPath, 'http://localhost')`, or whether normal fallback parsing continues.

## Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| S-001 | Issue describes a "Server-Side Request Forgery Vulnerability". | Scope is the server-side Node HTTP adapter. |
| S-002 | Issue states protocol-relative URLs are not relevant server-side and expected behavior could be an error. | Server-side protocol-relative request targets must reject. |
| S-003 | Issue localizes the defect to `new URL(fullPath, 'http://localhost')`. | The rejection must happen before this URL parse supplies a protocol. |
| S-004 | Issue says version 1.3.2 introduced the fallback base for relative paths. | Ordinary relative paths must continue to be parsed through the fallback base. |
| S-005 | `package.json` routes CommonJS default require to `dist/node/axios.cjs`. | Source and CommonJS Node bundle must remain behaviorally aligned. |

## Formal Predicate

Let `stripLead(P)` remove any leading URL-parser-trimmed C0 control or space characters from `P`. Let `sep(c)` hold when `c` is `/` or `\`.

`protocolRelative(P)` holds iff `stripLead(P)` begins with `c1 c2` where `sep(c1)` and `sep(c2)`.

The V2 implementation encodes this as:

```js
const isProtocolRelativeURL = /^[\u0000-\u0020]*[\\/]{2}/;
```

## Required Contracts

O-001: For all `fullPath`, if `protocolRelative(fullPath)`, the Node HTTP adapter rejects with `AxiosError.ERR_INVALID_URL` before URL parsing or transport creation.

O-002: For all `fullPath`, if `protocolRelative(fullPath)` is false, this guard does not reject and the adapter proceeds to the existing `new URL(fullPath, 'http://localhost')` path.

O-003: For a configured `baseURL` and a requested URL that `buildFullPath` leaves as protocol-relative, O-001 applies to the resulting `fullPath`.

O-004: For ordinary relative paths combined with `baseURL`, the resulting absolute full path does not satisfy `protocolRelative`, so O-002 preserves existing behavior.

O-005: O-001 and O-002 must hold in both `repo/lib/adapters/http.js` and `repo/dist/node/axios.cjs`.

## Formal Core

The K fragments are:

- `fvk/mini-js-url.k`
- `fvk/axios-url-spec.k`

Exact commands, not executed in this benchmark:

```sh
kompile fvk/mini-js-url.k --backend haskell
kast --backend haskell fvk/axios-url-spec.k
kprove fvk/axios-url-spec.k
```

Expected machine-check outcome after installing/running K: `#Top` for all claims.

