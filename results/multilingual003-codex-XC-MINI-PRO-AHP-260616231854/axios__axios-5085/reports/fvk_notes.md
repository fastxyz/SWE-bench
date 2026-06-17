# FVK Notes

## Summary

The FVK audit confirmed the V1 source-level fix but found one runtime mirror gap: the minified distribution bundles still used the old scalar-only `normalizeValue` helper. V2 fixes those two minified bundles. The main source and non-minified distribution edits from V1 stand unchanged.

## Decisions

1. Changed `repo/dist/axios.min.js`.

   Finding F-001 showed this minified runtime copy still used `function ue(e){return!1===e||null==e?e:String(e)}`, so `normalize()` could still stringify a `set-cookie` array in that bundle. Proof obligations O-001, O-003, and O-005 require array-preserving normalization in every runtime mirror. I changed the helper to recurse through arrays with `P.isArray(e)?e.map(ue):String(e)`.

2. Changed `repo/dist/esm/axios.min.js`.

   Finding F-001 identified the same mirror gap in the minified ESM bundle. O-005 requires runtime distribution consistency. I changed its helper to recurse through arrays with `x.isArray(e)?e.map(re):String(e)`.

3. Kept `repo/lib/core/AxiosHeaders.js` as V1.

   Finding F-004 and obligations O-001 through O-004 confirm the source fix is the right mechanism: `set()` already stores arrays, `normalize()` now preserves arrays through `normalizeValue`, and `get('set-cookie')` returns the stored value unchanged.

4. Kept `repo/dist/node/axios.cjs`, `repo/dist/axios.js`, and `repo/dist/esm/axios.js` as V1.

   These files already matched the source-level behavior after V1. O-005 still requires them as runtime mirrors, but the audit did not find further changes needed there.

5. Kept `toJSON()` unchanged.

   Finding F-002 and obligation O-006 reject a broader `toJSON()` change for this issue. The public reproduction and expected behavior are about `AxiosHeaders.get('set-cookie')`; changing request serialization would expand the API surface beyond the public intent.

6. Did not regenerate source maps.

   Finding F-003 records stale source maps as a release-process residual risk, not a runtime behavior bug. The task forbids running build tooling, and O-005 scopes runtime mirror consistency to executable JavaScript files.

## Verification Status

The proof is constructed, not machine-checked. I wrote the requested FVK artifacts plus supporting K files under `fvk/`, but did not run `kompile`, `kast`, `kprove`, tests, Python, or project code.
