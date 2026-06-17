# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are discharged by source inspection and the constructed K claims in `fvk/axiosheaders-spec.k`; the K commands were not run.

## O-001: Array-preserving value normalization

Claim: For any header value array `A = [v1, ..., vn]`, `normalizeValue(A)` returns `[normalizeValue(v1), ..., normalizeValue(vn)]`, preserving order and cardinality.

Evidence:

- `repo/lib/core/AxiosHeaders.js`
- `repo/dist/node/axios.cjs`
- `repo/dist/axios.js`
- `repo/dist/esm/axios.js`
- V2 minified mirror edits in `repo/dist/axios.min.js` and `repo/dist/esm/axios.min.js`

Constructed proof:

- Base case: empty array maps to empty array under JavaScript `Array.map`.
- Step case: for head `v` and tail `rest`, recursive element normalization gives `[normalizeValue(v), ...normalizeValue(rest)]`.
- Therefore a cookie-string array remains an array with the same ordered cookie strings.

Status: discharged.

## O-002: Sentinel and scalar frame preservation

Claim: `normalizeValue(false) = false`; `normalizeValue(null) = null`; scalar string values remain strings.

Evidence: Existing first guard remains before the array branch; scalar fallback remains `String(value)`.

Constructed proof:

- If the value is `false` or `null`, the first branch returns before array logic.
- If the value is a scalar string, it is not an array and `String(value)` is the same string.

Status: discharged.

## O-003: `AxiosHeaders.normalize()` must not comma-join arrays

Claim: Every `normalize()` assignment path uses the array-preserving `normalizeValue`, including the duplicate-key path and the normal header-name path.

Evidence:

- `normalize()` duplicate-key branch: `self[key] = normalizeValue(value)`
- `normalize()` normal branch: `self[normalized] = normalizeValue(value)`

Constructed proof:

- By O-001, if `value` is an array, either branch writes an array.
- No `String(array)` call remains on the `normalize()` path.

Status: discharged.

## O-004: `get('set-cookie')` after set + normalize returns the array

Claim: For `header = 'set-cookie'` and `value = [cookie1, cookie2, ...]`, `new AxiosHeaders({[header]: value}).normalize().get(header)` returns an array with the same ordered cookie strings.

Evidence:

- `set()` maps array elements through `normalizeValue` and stores an array.
- `normalize()` preserves array shape by O-003.
- `get()` with no parser returns the stored value unchanged.

Constructed proof:

1. `set()` receives an array and stores `value.map(normalizeValue)`.
2. For cookie strings, O-002 keeps each element unchanged.
3. `normalize()` rewrites only the header name/casing and stores `normalizeValue(array)`.
4. By O-001, the stored value remains an array.
5. `get(header)` finds the key and returns that stored value because no parser was supplied.

Status: discharged.

## O-005: Runtime mirror consistency

Claim: Every public runtime copy of the normalizer reachable from package/distribution entries has the array-preserving branch.

Runtime files in scope:

- `repo/lib/core/AxiosHeaders.js`
- `repo/dist/node/axios.cjs`
- `repo/dist/axios.js`
- `repo/dist/axios.min.js`
- `repo/dist/esm/axios.js`
- `repo/dist/esm/axios.min.js`

Constructed proof:

- V1 discharged this for source, Node CJS, non-minified UMD, and non-minified ESM.
- F-001 identified the two remaining minified runtime mirrors.
- V2 patched the minified helpers to call `map` recursively on arrays.

Status: discharged for runtime files. Source maps are excluded because they are non-runtime debug metadata and cannot be regenerated under the no-execution constraint.

## O-006: No unjustified API expansion

Claim: The fix must not change public signatures or unrelated serialization behavior.

Evidence:

- `AxiosHeaders.get(name)` already returns `AxiosHeaderValue`; that type includes `string[]`.
- `RawAxiosResponseHeaders` already includes `"set-cookie"?: string[]`.
- The issue names `get('set-cookie')`, not `toJSON()`.

Constructed proof:

- Adding the array branch to `normalizeValue` changes the stored value shape only where the implementation had already accepted arrays.
- No method signature changes.
- `toJSON()` remains unchanged, so request serialization policy is not broadened in this task.

Status: discharged.
