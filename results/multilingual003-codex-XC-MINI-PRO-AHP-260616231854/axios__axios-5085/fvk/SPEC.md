# FVK Spec: axios__axios-5085

Status: constructed, not machine-checked. No tests, project code, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 fix for `AxiosHeaders.get('set-cookie')` returning a comma-joined string instead of an array after Axios response header normalization.

Primary implementation units:

- `repo/lib/core/AxiosHeaders.js`: `normalizeValue`, `set`, `normalize`, `get`.
- `repo/lib/helpers/parseHeaders.js`: raw duplicate `set-cookie` handling.
- `repo/lib/core/transformData.js`: response transform path that calls `headers.normalize()`.
- Runtime mirrors under `repo/dist/`.

## Intent Spec

I-001: Multiple `Set-Cookie` response headers are represented as an ordered array of cookie strings.

I-002: `AxiosHeaders.get('set-cookie')`, with no parser argument, must return that array after response processing and header normalization.

I-003: The fix must prevent array-valued `set-cookie` headers from being stringified with JavaScript comma joining, because a cookie string may itself contain commas, notably in an `Expires` attribute.

I-004: Header normalization should still normalize array elements individually and preserve existing sentinel behavior for `false`, `null`, and `undefined`.

I-005: Public runtime copies of `AxiosHeaders` should agree with the source behavior.

Out of scope for this issue:

- `AxiosHeaders.toJSON()` request serialization policy.
- `AxiosHeaders.get(name, parser)` behavior when a parser is supplied for an array-valued header.
- Source-map fidelity, because source maps are not runtime behavior and the task forbids running the build.

## Public Evidence Ledger

E-001: Source `benchmark/PROBLEM.md`.
Quote: "With version 0.27.2 or older when reading the `response.headers['set-cookie']` it returned an array of cookies."
Obligation: preserve ordered array shape for multiple `Set-Cookie` values.
Status: encoded by O-001 through O-004.

E-002: Source `benchmark/PROBLEM.md`.
Quote: "Since version 1.x when reading `response.headers.get('set-cookie')` it returns a string."
Obligation: the current comma-joined string is the legacy bug, not a behavior to preserve.
Status: encoded by O-003 and Finding F-001.

E-003: Source `benchmark/PROBLEM.md`.
Quote: "AxiosHeaders.get('set-cookie') should return an array of cookies."
Obligation: the observable is `get('set-cookie')`, with no parser argument.
Status: encoded by O-004.

E-004: Source `benchmark/PROBLEM.md`.
Quote: "I'm passing `response.headers['set-cookie']` to set-cookie-parser. It can parse arrays and strings with one cookie but not what axios returns currently (a string with multiple cookies)."
Obligation: do not represent multiple cookies as one comma-joined string.
Status: encoded by O-001 and O-003.

E-005: Source `repo/index.d.ts`.
Evidence: `RawAxiosResponseHeaders` has `"set-cookie"?: string[]`.
Obligation: returning `string[]` for response `set-cookie` is compatible with the public type surface.
Status: encoded by O-006.

E-006: Source `repo/package.json`.
Evidence: package consumers can reach `index.js`, `dist/node/axios.cjs`, browser bundles, and CDN bundles.
Obligation: runtime distribution mirrors should not retain the old normalizer.
Status: encoded by O-005 and Finding F-001.

## Formal Model

Supporting K artifacts:

- `fvk/mini-axios-headers.k`
- `fvk/axiosheaders-spec.k`

The model abstracts only the property-relevant fragment:

- header values are `false`, `null`, scalar strings, or arrays of header values;
- `normalizeValue` returns `false` and `null` unchanged;
- `normalizeValue` maps arrays element by element;
- scalar strings remain scalar strings;
- `setGet` models `AxiosHeaders.set(...)` followed by `get(...)`;
- `normalizeGet` models `set(...)`, `normalize()`, then `get(...)`.

Property axis preserved in the model: output shape, order, cardinality, and string elements. This distinguishes the passing value `[cookie1, cookie2]` from the failing value `"cookie1,cookie2"`.

## Formal English Claims

C-001: For any two cookie strings `C1` and `C2`, `normalizeGet("set-cookie", [C1, C2])` returns `[C1, C2]`.
Adequacy: passes I-001, I-002, and I-003.

C-002: For any array-valued header value `VS`, `normalizeValue(VS)` returns an array with the same order and cardinality, with `normalizeValue` applied to each element.
Adequacy: passes I-004.

C-003: `normalizeValue(false)` returns `false`; `normalizeValue(null)` returns `null`.
Adequacy: passes I-004 and frame preservation.

C-004: `normalizeValue(str(S))` returns `str(S)`.
Adequacy: passes scalar frame preservation.

## Compatibility Audit

No public method signatures were changed.

`AxiosHeaders.get(name)` already returns `AxiosHeaderValue` in `repo/index.d.ts`, and `AxiosHeaderValue` includes `string[]`. The response header type already includes `"set-cookie"?: string[]`.

V2 updates the two minified runtime bundles so the public runtime copies now match V1 source and non-minified distributions. Source maps were not regenerated because the task forbids running the build; they are not runtime inputs to the proof.
