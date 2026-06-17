# Baseline Notes

## Root cause

Node exposes multiple `Set-Cookie` response headers as an array on `res.headers['set-cookie']`, and `AxiosHeaders.set()` initially preserved array values. The array was later lost during response transformation: `transformData()` calls `headers.normalize()`, and `AxiosHeaders.normalize()` passed every header value through `normalizeValue()`. `normalizeValue()` converted non-null values with `String(value)`, so a cookie array became a single comma-joined string. That is not a valid representation for multiple `Set-Cookie` headers because cookie attributes such as `Expires` can also contain commas.

## Files changed

- `repo/lib/core/AxiosHeaders.js`: Updated `normalizeValue()` to preserve arrays while recursively normalizing their individual entries. This keeps `AxiosHeaders.get('set-cookie')` returning the original array after response header normalization.
- `repo/dist/node/axios.cjs`: Applied the same change to the CommonJS distribution entry used by package consumers through the `exports` `require` path.
- `repo/dist/esm/axios.js`: Applied the same change to the non-minified ESM browser distribution so the distributable bundle matches the source behavior.
- `repo/dist/axios.js`: Applied the same change to the non-minified UMD browser distribution so the distributable bundle matches the source behavior.

## Assumptions and alternatives considered

- I assumed the intended behavior is not specific to a new `getSetCookie()` API; the issue explicitly expects `AxiosHeaders.get('set-cookie')` to return `string[]`, and the existing TypeScript response header type already allows `"set-cookie"?: string[]`.
- I considered special-casing only the `set-cookie` header inside `normalize()`, but rejected that because `AxiosHeaders.set()` already treats arrays as valid header values generally. Preserving array shape in the shared value normalizer is the smaller and more consistent fix.
- I considered changing `toJSON()` to preserve arrays as arrays. I left it unchanged because the reported failure is `get('set-cookie')` after response normalization, while `toJSON()` is used for request serialization and currently joins arrays deliberately.
- I did not run tests or execute project code, per the benchmark instruction that this session has no execution environment.
