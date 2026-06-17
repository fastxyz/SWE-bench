# FVK Specification: axios HTTP `maxBodyLength` Transport Option

Status: constructed, not machine-checked. No tests, Node code, Python, or K tooling were run.

## Scope

This FVK pass audits the source slice in `repo/lib/adapters/http.js` that chooses the Node transport and populates `options.maxBodyLength` before calling `transport.request(options, ...)`.

The modeled input state is:

- `maxBodyLength`: a legal axios numeric request-body limit, modeled as `finite(N)` or `inf`.
- `hasCustomTransport`: whether `config.transport` is present.
- `redirectsDisabled`: whether `config.maxRedirects === 0`.

The modeled output is:

- selected transport class: `custom`, `native`, or `follow`.
- downstream `options.maxBodyLength`: `finite(N)`, `inf`, or `omitted`.

`NaN`, `null`, non-number limits, and external transport internals are outside this proof domain because the public API evidence only types `maxBodyLength` as `number` and the issue concerns axios' documented/default numeric sentinel values.

## Intent-Only Specification

1. Axios' default `maxBodyLength` sentinel `-1` means no axios request-body limit.
2. An explicit `maxBodyLength: -1` has the same unlimited meaning as the default.
3. Redirect-capable default requests must not inherit `follow-redirects`' own finite default limit.
4. When axios uses `follow-redirects` and the axios limit is unlimited, axios must pass `Infinity` downstream.
5. Explicit finite values greater than `-1` must remain enforceable and be passed unchanged.
6. Explicit `maxBodyLength: Infinity` must be treated as an unlimited explicit value and passed unchanged.
7. `maxRedirects: 0` must remain unlimited for the axios default case, because it uses Node's native transport rather than `follow-redirects`.
8. The compatibility frame is narrow: do not change public signatures or custom transport behavior unless needed to satisfy the issue.
9. The issue also names a documentation gap. This benchmark repair target is non-test source code, so the documentation item is recorded as a residual finding rather than changed here.

## Public Evidence Ledger

| Id | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "previously, there was no request payload limit" | Default axios request body limit is unlimited. | Encoded by C1/C2. |
| E2 | `benchmark/PROBLEM.md` | "`axios.post('/size', 'x'.repeat(1e8))` -> Error" is reported as bug behavior | Default redirect-capable request must not fail due to a 10 MB inherited default. | Encoded by C1. |
| E3 | `benchmark/PROBLEM.md` | "`{ maxBodyLength: -1 }` -> Error" is reported as bug behavior | Explicit `-1` is in-domain and unlimited. | Encoded by C2. |
| E4 | `benchmark/PROBLEM.md` | "`{ maxRedirects: 0 }` -> OK" | No-redirect native path is already unlimited and must remain OK. | Encoded by C6. |
| E5 | `benchmark/PROBLEM.md` | "`{ maxBodyLength: Infinity }` -> OK" | Explicit `Infinity` is an unlimited value accepted by the transport path. | Encoded by C3/C4/C5. |
| E6 | Public hint | "if axios limit is set to `-1` then `Infinity` should be passed to follow-redirects" | Follow transport must receive `Infinity` for axios unlimited sentinel values. | Encoded by C1/C2. |
| E7 | `repo/lib/defaults/index.js` | `maxBodyLength: -1` | The default config value is `-1`. | Implementation evidence supporting E1/E3. |
| E8 | `repo/lib/adapters/http.js` | preflight check only rejects when `config.maxBodyLength > -1` | Adapter already treats values not greater than `-1` as unlimited for buffered request data. | Frame condition; unchanged. |
| E9 | `repo/lib/adapters/http.js` | `config.transport`, `config.maxRedirects === 0`, else follow transport | Transport selection branches are the complete source slice to audit. | Encoded by all claims. |
| E10 | `repo/lib/core/mergeConfig.js` | `transport` is merged as a config property | Custom transport is a supported implementation path; avoid changing its default option shape without intent evidence. | Encoded by C7 after V2. |

## Formal Claims

The machine-checkable core is in:

- `fvk/mini-axios-http-options.k`
- `fvk/axios-http-options-spec.k`

Claim map:

- C1 `DEFAULT-FOLLOW-UNLIMITED`: `compute(finite(-1), false, false) -> res(follow, inf)`.
- C2 `UNLIMITED-FOLLOW-FAMILY`: any finite numeric `maxBodyLength` not greater than `-1` on the follow path maps to `inf`.
- C3 `FINITE-CUSTOM-PASSTHROUGH`: greater-than-`-1` values pass through to custom transport.
- C4 `FINITE-NATIVE-PASSTHROUGH`: greater-than-`-1` values pass through to native transport.
- C5 `FINITE-FOLLOW-PASSTHROUGH`: greater-than-`-1` values pass through to follow transport.
- C6 `NATIVE-UNLIMITED-COMPAT`: unlimited native no-redirect path keeps downstream `maxBodyLength` omitted.
- C7 `CUSTOM-UNLIMITED-COMPAT`: unlimited custom transport path keeps downstream `maxBodyLength` omitted.

## Formal Spec English

- If axios selects `follow-redirects` and the axios body limit is the default/unlimited finite sentinel, the downstream transport option must be `Infinity`.
- If axios selects any transport and `maxBodyLength > -1`, the downstream value must equal the explicit user value.
- If axios selects native `http`/`https` because `maxRedirects === 0` and the axios body limit is unlimited, no `maxBodyLength` override is needed or added.
- If a custom transport is supplied and the axios body limit is unlimited, no new `maxBodyLength` override is added by this fix.

## Adequacy Audit

| Claim | Public intent match | Result |
| --- | --- | --- |
| C1/C2 | Directly matches E1, E2, E3, E6. | Pass. |
| C3/C4/C5 | Matches E5 and preserves existing finite-limit behavior from E8. | Pass. |
| C6 | Matches E4 while preserving native option shape. | Pass. |
| C7 | Not directly required by the issue, but required by compatibility evidence E10 and minimal-change scope. | Pass. |

No claim relies on the pre-fix error as intended behavior. The pre-fix error examples are treated as SUSPECT legacy behavior because the issue presents them as the bug.

## Public Compatibility Audit

- Public signatures: unchanged.
- TypeScript declarations: unchanged.
- `maxBodyLength` finite behavior: preserved by C3/C4/C5.
- `maxRedirects: 0` behavior: remains unlimited; the native request option shape for unlimited values is restored to V0 by V2.
- `config.transport`: semi-public implementation path from `mergeConfig`; V2 preserves V0 omission of `options.maxBodyLength` for unlimited values on custom transports.
- Documentation: public issue requests documentation, but this source-code benchmark phase does not edit docs. Recorded in `FINDINGS.md`.
