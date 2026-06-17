# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and constructed proof obligations. No tests or project code were run.

## F-001: V1 left minified runtime mirrors with the old normalizer

Classification: code bug in generated/runtime mirror.

Evidence: `repo/package.json` names browser/CDN distribution files, and FVK's mirror rule requires duplicated runtime copies of the behavior to agree. V1 patched `repo/lib/core/AxiosHeaders.js`, `repo/dist/node/axios.cjs`, `repo/dist/esm/axios.js`, and `repo/dist/axios.js`, but the minified runtime files still contained scalar-only normalizers:

- `repo/dist/axios.min.js`: `function ue(e){return!1===e||null==e?e:String(e)}`
- `repo/dist/esm/axios.min.js`: `function re(e){return!1===e||null==e?e:String(e)}`

Input -> observed vs expected:

- Input: minified bundle path receives a header object with `'set-cookie': ['a=1; Expires=Wed, 12 Apr 2023 12:05:15 GMT', 'b=2']`, then response transforms call `normalize()`, then user calls `get('set-cookie')`.
- Observed in V1 by code inspection: `normalize()` called the old minified helper, which applied `String(array)` and produced one comma-joined string.
- Expected from E-001 through E-004: `get('set-cookie')` returns the original ordered array.

Resolution: fixed in V2 by changing the minified helpers to preserve arrays:

- `repo/dist/axios.min.js`: `P.isArray(e)?e.map(ue):String(e)`
- `repo/dist/esm/axios.min.js`: `x.isArray(e)?e.map(re):String(e)`

Related proof obligations: O-001, O-003, O-005.

## F-002: `toJSON()` array joining is not part of this issue contract

Classification: rejected change / scope boundary.

Evidence: The issue's expected behavior names `AxiosHeaders.get('set-cookie')`, not `toJSON()`. The reproduction calls `response2.headers.get('set-cookie')`.

Input -> observed vs expected:

- Input: `AxiosHeaders` instance with array-valued header passed through `toJSON()`.
- Observed: implementation joins arrays with `', '`.
- Expected for this issue: no expectation; `toJSON()` is request serialization-oriented in the observed call sites and is not the reported response observable.

Resolution: left unchanged. Changing `toJSON()` would be a broader API and request-serialization change not justified by the public issue.

Related proof obligations: O-006.

## F-003: Source maps were not regenerated

Classification: release-process residual risk, not a runtime behavior bug for this task.

Evidence: V1 and V2 directly edited runtime JavaScript files. The task forbids running build tooling, so generated `.map` files were not regenerated.

Input -> observed vs expected:

- Input: devtools or source-map consumer reads a changed distribution file with an old source map.
- Observed: source-map content may not exactly reflect the manual edits.
- Expected for runtime issue: runtime JavaScript returns arrays from `get('set-cookie')`.

Resolution: no source-map edit. If a release process requires source-map fidelity, regenerate distribution artifacts with the normal build outside this no-execution benchmark.

Related proof obligations: O-005 only for runtime files; source maps are excluded from O-005.

## F-004: V1 source-level fix satisfies the main intent

Classification: confirmed behavior.

Evidence: `repo/lib/core/AxiosHeaders.js` now makes `normalizeValue(array)` return `array.map(normalizeValue)`. `set()` already preserves arrays, `normalize()` now calls the array-preserving normalizer, and `get()` with no parser returns the stored value unchanged.

Input -> observed vs expected:

- Input: source path receives `'set-cookie': ['a=1', 'b=2']`, response transform calls `normalize()`, user calls `get('set-cookie')`.
- Observed after V1/V2 by code inspection and constructed proof: `['a=1', 'b=2']`.
- Expected from E-003: array of cookies.

Resolution: no further source-level change beyond V1 was needed.

Related proof obligations: O-001 through O-004.
